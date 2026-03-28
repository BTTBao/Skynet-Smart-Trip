using SmartTrip.Application.DTOs.Auth;
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

        public AuthService(IUserRepository userRepository, ITokenService tokenService, IEmailService emailService)
        {
            _userRepository = userRepository;
            _tokenService = tokenService;
            _emailService = emailService;
        }

        public async Task<AuthResultDto> LoginAsync(LoginRequestDto request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);

            if (user == null)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Tài khoản không tồn tại." };
            }

            if (user.IsActive == false)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Tài khoản đã bị khóa." };
            }

            bool isPasswordValid = VerifyPassword(request.Password, user.PasswordHash);

            if (!isPasswordValid)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Mật khẩu không chính xác." };
            }

            string jwtToken = _tokenService.GenerateToken(user.Email);

            return new AuthResultDto
            {
                IsSuccess = true,
                Token = jwtToken 
            };
        }

        public async Task<AuthResultDto> RegisterAsync(RegisterRequestDto request)
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

            _ = _emailService.SendEmailAsync(newUser.Email, "Chào mừng đến với SmartTrip", $"Xin chào {newUser.FullName}, tài khoản của bạn đã được tạo thành công.");

            return new AuthResultDto { IsSuccess = true };
        }

        public async Task<bool> ForgotPasswordAsync(ForgotPasswordRequestDto request)
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

        public async Task<bool> ResetPasswordAsync(ResetPasswordRequestDto request)
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
    }
}
