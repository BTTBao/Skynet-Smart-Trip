using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Auth;
using SmartTrip.Application.DTOs.Auth.ForgotPassword;
using SmartTrip.Application.DTOs.Auth.Login;
using SmartTrip.Application.DTOs.Auth.Register;
using SmartTrip.Application.DTOs.Auth.ResetPassword;
using SmartTrip.Application.Interfaces.Auth;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly ITokenService _tokenService;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            IUserRepository userRepository, 
            ITokenService tokenService, 
            IEmailService emailService, 
            IConfiguration configuration, ILogger<AuthService> logger)
        {
            _userRepository = userRepository;
            _tokenService = tokenService;
            _emailService = emailService;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<AuthResultDto> LoginAsync(LoginRequest request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);

            if (user == null || !VerifyPassword(request.Password, user.PasswordHash))
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Email hoặc mật khẩu không chính xác." };
            }

            if (user.IsActive == false)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Tài khoản của bạn đã bị khóa." };
            }

            int expireMinutes = int.Parse(_configuration["Jwt:ExpireMinutes"] ?? "60");

            string jwtToken = _tokenService.GenerateToken(user.Email, expireMinutes);

            return new AuthResultDto
            {
                IsSuccess = true,
                Token = jwtToken,
                ExpiresIn = expireMinutes * 60
            };
        }

        public async Task<AuthResultDto> RegisterAsync(RegisterRequest request)
        {
            var existingUser = await _userRepository.GetUserByEmailAsync(request.Email);
            if (existingUser != null)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Email đã được sử dụng." };
            }

            string hashedPassword = BCrypt.Net.BCrypt.HashPassword(request.Password);

            var newUser = new User
            {
                Email = request.Email,
                PasswordHash = hashedPassword,
                FullName = request.FullName,
                Phone = request.Phone,
                Role = UserRole.User, 
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                AuthProvider = AuthProvider.Local 
            };

            bool isCreated = await _userRepository.AddUserAsync(newUser);

            if (!isCreated)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Lỗi khi lưu vào cơ sở dữ liệu." };
            }

            await SendWelcomeEmailAsync(newUser);

            return new AuthResultDto { IsSuccess = true };
        }

        public async Task<bool> ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);
            if (user == null || user.IsActive == false)
            {
                return false; 
            }

            string resetToken = Guid.NewGuid().ToString();

            string resetLink = $"https://yourfrontend.com/reset-password?email={user.Email}&token={resetToken}";
            string mailContent = $"Vui lòng click vào link sau để đặt lại mật khẩu của bạn: <a href='{resetLink}'>Đặt lại mật khẩu</a>";

            await _emailService.SendEmailAsync(user.Email, "Yêu cầu khôi phục mật khẩu Smart Trip", mailContent);

            return true;
        }

        public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);
            if (user == null) return false;

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);

            return await _userRepository.UpdateUserAsync(user);
        }

        private bool VerifyPassword(string inputPassword, string? storedHash)
        {
            if (string.IsNullOrEmpty(storedHash))
                return false;

            try
            {
                return BCrypt.Net.BCrypt.Verify(inputPassword, storedHash);
            }
            catch (BCrypt.Net.SaltParseException)
            {
                return false;
            }
        }

        private async Task SendWelcomeEmailAsync(User user)
        {
            try
            {
                await _emailService.SendEmailAsync(
                    user.Email,
                    "Chào mừng đến với SmartTrip",
                    $"Xin chào {user.FullName}, tài khoản của bạn đã được tạo thành công."
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Gửi email chào mừng thất bại cho {Email}", user.Email);
            }
        }
    }
}
