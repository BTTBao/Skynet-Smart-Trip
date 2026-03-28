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

            // Dùng BCrypt để verify mật khẩu
            bool isPasswordValid = VerifyPassword(request.Password, user.PasswordHash);

            if (!isPasswordValid)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Mật khẩu không chính xác." };
            }

            // Mật khẩu đúng -> AuthService tự sinh token thông qua TokenService
            string jwtToken = _tokenService.GenerateToken(user.Email);  // Hoặc đổi truyền UserId sang tuỳ bạn

            return new AuthResultDto
            {
                IsSuccess = true,
                Token = jwtToken // Trả trực tiếp Token ra ngoài
            };
        }

        public async Task<AuthResultDto> RegisterAsync(RegisterRequestDto request)
        {
            // Kiểm tra email tồn tại chưa
            var existingUser = await _userRepository.GetUserByEmailAsync(request.Email);
            if (existingUser != null)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Email đã được sử dụng." };
            }

            // Mã hoá mật khẩu
            string hashedPassword = BCrypt.Net.BCrypt.HashPassword(request.Password);

            // Tạo đối tượng User
            var newUser = new User
            {
                Email = request.Email,
                PasswordHash = hashedPassword,
                FullName = request.FullName,
                Phone = request.Phone,
                Role = UserRole.User.ToString(), // Gán quyền MẶC ĐỊNH
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                AuthProvider = "Local" // Phân biệt với Google/Facebook login
            };

            bool isCreated = await _userRepository.AddUserAsync(newUser);

            if (!isCreated)
            {
                return new AuthResultDto { IsSuccess = false, ErrorMessage = "Lỗi khi lưu vào cơ sở dữ liệu." };
            }

            // (Tuỳ chọn) Gửi mail Welcome
            _ = _emailService.SendEmailAsync(newUser.Email, "Chào mừng đến với SmartTrip", $"Xin chào {newUser.FullName}, tài khoản của bạn đã được tạo thành công.");

            return new AuthResultDto { IsSuccess = true };
        }

        public async Task<bool> ForgotPasswordAsync(ForgotPasswordRequestDto request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);
            if (user == null || user.IsActive == false)
            {
                return false; // Tránh lộ thông tin email có tồn tại hay không cho hacker
            }

            // Sinh Reset Token bảo mật. (Cách đơn giản: dùng một JWT ngắn hạn, hoặc Random String lưu vào Cache/DB).
            // Ở đây mình ví dụ sinh chuỗi ngẫu nhiên (nếu dùng DB, bạn nên có cột ResetPasswordToken ở Entity User).
            // VD tạm: Ta gửi link có 1 token giả lập.
            string resetToken = Guid.NewGuid().ToString();

            // TODO: Ở hệ thống thực, cần lưu resetToken vào cache (Redis) với hạn 15 phút kèm theo email,
            // HOẶC thêm 2 trường `ResetToken` và `ResetTokenExpiry` vào table `User` và lưu csdl.

            string resetLink = $"https://yourfrontend.com/reset-password?email={user.Email}&token={resetToken}";
            string mailContent = $"Vui lòng click vào link sau để đặt lại mật khẩu của bạn: <a href='{resetLink}'>Đặt lại mật khẩu</a>";

            await _emailService.SendEmailAsync(user.Email, "Yêu cầu khôi phục mật khẩu Smart Trip", mailContent);

            return true;
        }

        public async Task<bool> ResetPasswordAsync(ResetPasswordRequestDto request)
        {
            var user = await _userRepository.GetUserByEmailAsync(request.Email);
            if (user == null) return false;

            // TODO: Verify cái `request.Token` với Database/Cache xem còn hạn không và có khớp không.
            // if (user.ResetToken != request.Token || user.ResetTokenExpiry < DateTime.UtcNow) return false;

            // Cập nhật pass mới
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            // Xóa token đi (để dùng 1 lần)
            // user.ResetToken = null;

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
