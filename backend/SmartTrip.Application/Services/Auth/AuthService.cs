using Google.Apis.Auth;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SmartTrip.Application.Configurations;
using SmartTrip.Application.DTOs.Auth;
using SmartTrip.Application.DTOs.Auth.ForgotPassword;
using SmartTrip.Application.DTOs.Auth.Login;
using SmartTrip.Application.DTOs.Auth.RefreshToken;
using SmartTrip.Application.DTOs.Auth.Register;
using SmartTrip.Application.DTOs.Auth.ResetPassword;
using SmartTrip.Application.DTOs.Auth.VerifyEmail;
using SmartTrip.Application.Interfaces.Auth;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Application.Services.Auth
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly ITokenService _tokenService;
        private readonly GoogleAuthSettings _googleSettings;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthService> _logger;

        private int AccessTokenExpireMinutes =>
            int.Parse(_configuration["Jwt:ExpireMinutes"] ?? "60");

        private int RefreshTokenExpireDays =>
            int.Parse(_configuration["Jwt:RefreshTokenExpireDays"] ?? "7");

        public AuthService(
            IUserRepository userRepository,
            ITokenService tokenService,
            IOptions<GoogleAuthSettings> googleSettings,
            IEmailService emailService,
            IConfiguration configuration,
            ILogger<AuthService> logger)
        {
            _userRepository = userRepository;
            _tokenService = tokenService;
            _googleSettings = googleSettings.Value;
            _emailService = emailService;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<AuthResultDto> LoginAsync(LoginRequest request)
        {
            // Phát hiện identifier là email hay username
            var isEmail = request.Identifier.Contains('@');
            var user = isEmail
                ? await _userRepository.GetUserByEmailAsync(request.Identifier)
                : await _userRepository.GetUserByUsernameAsync(request.Identifier);

            if (user == null || !VerifyPassword(request.Password, user.PasswordHash))
                return Fail("Email/Tên đăng nhập hoặc mật khẩu không chính xác.");

            if (user.IsActive == false)
                return Fail("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.");

            if (!user.IsEmailVerified)
                return Fail("Email chưa được xác thực. Vui lòng kiểm tra hòm thư và xác thực tài khoản.");

            var accessToken = _tokenService.GenerateAccessToken(user, AccessTokenExpireMinutes);
            var refreshToken = _tokenService.GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(RefreshTokenExpireDays);
            user.LastLoginAt = DateTime.UtcNow;

            await _userRepository.UpdateUserAsync(user);

            return new AuthResultDto
            {
                IsSuccess = true,
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresIn = AccessTokenExpireMinutes * 60
            };
        }

        public async Task<AuthResultDto> LoginWithGoogleAsync(GoogleLoginRequest request)
        {
            GoogleJsonWebSignature.Payload payload;

            try
            {
                // Validate ID Token với Google
                var validationSettings = new GoogleJsonWebSignature.ValidationSettings
                {
                    // So khớp Audience với tất cả Client IDs 
                    Audience = _googleSettings.GoogleClientIds.GetAllIds()
                };

                payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, validationSettings);
            }
            catch (InvalidJwtException)
            {
                return Fail("Token Google không hợp lệ hoặc đã hết hạn.");
            }

            // tìm user theo email
            var user = await _userRepository.GetUserByEmailAsync(payload.Email);

            if (user == null)
            {
                // nếu user mới 
                user = new User 
                {
                    Email = payload.Email,
                    FullName = payload.Name,
                    AvatarUrl = payload.Picture, 
                    IsEmailVerified = payload.EmailVerified,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,

                    AuthProvider = AuthProvider.Google,
                    // payload.Subject chính là chuỗi ID duy nhất của Google cho user này
                    SocialId = payload.Subject
                };

                await _userRepository.AddUserAsync(user); 
            }
            else
            {
                // user đã tồn tại
                if (user.IsActive == false)
                    return Fail("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.");

                if (string.IsNullOrEmpty(user.AuthProvider.ToString()) || user.AuthProvider != AuthProvider.Google)
                {
                    user.AuthProvider = AuthProvider.Google;
                    user.SocialId = payload.Subject;
                    user.IsEmailVerified = true; 
                }
            }

            // generate access/refresh token 
            var accessToken = _tokenService.GenerateAccessToken(user, AccessTokenExpireMinutes);
            var refreshToken = _tokenService.GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(RefreshTokenExpireDays);
            user.LastLoginAt = DateTime.UtcNow;

            await _userRepository.UpdateUserAsync(user);

            return new AuthResultDto
            {
                IsSuccess = true,
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresIn = AccessTokenExpireMinutes * 60
            };
        }

        public async Task<AuthResultDto> RegisterAsync(RegisterRequest request)
        {
            var existingEmail = await _userRepository.GetUserByEmailAsync(request.Email);
            if (existingEmail != null)
                return Fail("Email này đã được sử dụng.");

            var existingUsername = await _userRepository.GetUserByUsernameAsync(request.UserName);
            if (existingUsername != null)
                return Fail("Tên đăng nhập này đã được sử dụng.");

            var verificationToken = new Random().Next(100000, 999999).ToString();

            var newUser = new User
            {
                Email = request.Email,
                UserName = request.UserName.ToLower(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                FullName = request.FullName,
                Phone = request.Phone,
                Role = UserRole.User,
                IsActive = true,
                IsEmailVerified = false,
                EmailVerificationToken = verificationToken,
                EmailVerificationTokenExpiry = DateTime.UtcNow.AddMinutes(15),
                AuthProvider = AuthProvider.Local,
                CreatedAt = DateTime.UtcNow
            };

            bool isCreated = await _userRepository.AddUserAsync(newUser);
            if (!isCreated)
                return Fail("Lỗi khi tạo tài khoản. Vui lòng thử lại.");

            await SendVerificationEmailSafeAsync(newUser, verificationToken);

            return new AuthResultDto { IsSuccess = true };
        }

        public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            // Always return success to prevent email enumeration
            var user = await _userRepository.GetUserByEmailAsync(request.Email);
            if (user == null || user.IsActive == false) return;

            var resetToken = Guid.NewGuid().ToString("N");
            var frontendUrl = _configuration["FrontendUrl"] ?? "https://smarttrip.vn";

            user.PasswordResetToken = resetToken;
            user.PasswordResetTokenExpiry = DateTime.UtcNow.AddMinutes(15);

            await _userRepository.UpdateUserAsync(user);

            var resetLink = $"{frontendUrl}/reset-password?token={resetToken}";

            try
            {
                await _emailService.SendPasswordResetEmailAsync(
                    user.Email,
                    user.FullName ?? user.Email,
                    resetLink);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send password reset email to {Email}", user.Email);
                // Token is already saved — user can retry
            }
        }

        public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _userRepository.GetUserByResetTokenAsync(request.Token);

            if (user == null)
            {
                _logger.LogWarning("ResetPassword: invalid token attempt");
                return false;
            }

            if (user.PasswordResetTokenExpiry == null || user.PasswordResetTokenExpiry < DateTime.UtcNow)
            {
                _logger.LogWarning("ResetPassword: expired token for {Email}", user.Email);
                return false;
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.PasswordResetToken = null;
            user.PasswordResetTokenExpiry = null;
            // Invalidate all existing sessions after password change
            user.RefreshToken = null;
            user.RefreshTokenExpiry = null;

            return await _userRepository.UpdateUserAsync(user);
        }

        public async Task<bool> VerifyEmailAsync(VerifyEmailRequest request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);

            if (user == null || user.EmailVerificationToken != request.Otp)
            {
                _logger.LogWarning("VerifyEmail: invalid otp attempt for {Email}", request.Email);
                return false;
            }

            if (user.EmailVerificationTokenExpiry == null || user.EmailVerificationTokenExpiry < DateTime.UtcNow)
            {
                _logger.LogWarning("VerifyEmail: expired otp for {Email}", user.Email);
                return false;
            }

            user.IsEmailVerified = true;
            user.EmailVerificationToken = null;
            user.EmailVerificationTokenExpiry = null;

            return await _userRepository.UpdateUserAsync(user);
        }

        public async Task<AuthResultDto> RefreshTokenAsync(RefreshTokenRequest request)
        {
            var user = await _userRepository.GetUserByRefreshTokenAsync(request.RefreshToken);

            if (user == null)
                return Fail("Refresh token không hợp lệ.");

            if (user.RefreshTokenExpiry == null || user.RefreshTokenExpiry < DateTime.UtcNow)
                return Fail("Refresh token đã hết hạn. Vui lòng đăng nhập lại.");

            if (user.IsActive == false)
                return Fail("Tài khoản đã bị khóa.");

            var newAccessToken = _tokenService.GenerateAccessToken(user, AccessTokenExpireMinutes);
            var newRefreshToken = _tokenService.GenerateRefreshToken();

            user.RefreshToken = newRefreshToken;
            user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(RefreshTokenExpireDays);

            await _userRepository.UpdateUserAsync(user);

            return new AuthResultDto
            {
                IsSuccess = true,
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken,
                ExpiresIn = AccessTokenExpireMinutes * 60
            };
        }

        public async Task<bool> RevokeRefreshTokenAsync(string refreshToken)
        {
            var user = await _userRepository.GetUserByRefreshTokenAsync(refreshToken);
            if (user == null) return false;

            user.RefreshToken = null;
            user.RefreshTokenExpiry = null;

            return await _userRepository.UpdateUserAsync(user);
        }

        // ──────────────────────────────────────────────
        // Private helpers
        // ──────────────────────────────────────────────

        private static AuthResultDto Fail(string message) =>
            new() { IsSuccess = false, ErrorMessage = message };

        private static bool VerifyPassword(string inputPassword, string? storedHash)
        {
            if (string.IsNullOrEmpty(storedHash)) return false;
            try { return BCrypt.Net.BCrypt.Verify(inputPassword, storedHash); }
            catch (BCrypt.Net.SaltParseException) { return false; }
        }

        private async Task SendVerificationEmailSafeAsync(User user, string token)
        {
            try
            {
                await _emailService.SendEmailVerificationAsync(
                    user.Email,
                    user.FullName ?? user.Email,
                    token);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send verification email to {Email}", user.Email);
            }
        }

    }
}
