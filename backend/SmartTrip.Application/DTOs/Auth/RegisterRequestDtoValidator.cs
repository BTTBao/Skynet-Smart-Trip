using FluentValidation;
using SmartTrip.Application.DTOs.Auth;

namespace SmartTrip.Application.DTOs.Auth
{
    public class RegisterRequestDtoValidator : AbstractValidator<RegisterRequestDto>
    {
        public RegisterRequestDtoValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email không được để trống.")
                .EmailAddress().WithMessage("Email không đúng định dạng.");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Mật khẩu không được để trống.")
                .MinimumLength(6).WithMessage("Mật khẩu phải từ 6 ký tự trở lên.");

            RuleFor(x => x.FullName)
                .NotEmpty().WithMessage("Họ tên không được để trống.");
        }
    }
}