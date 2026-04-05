using FluentValidation;
using SmartTrip.Application.DTOs.Auth;

namespace SmartTrip.Application.DTOs.Auth
{
    public class LoginRequestDtoValidator : AbstractValidator<LoginRequestDto>
    {
        public LoginRequestDtoValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email không được để trống.")
                .EmailAddress().WithMessage("Email không đúng định dạng.");
            
            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Mật khẩu không được để trống.");
        }
    }
}