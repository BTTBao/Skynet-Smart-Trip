using FluentValidation;

namespace SmartTrip.Application.DTOs.Auth
{
    public class ResetPasswordRequestDtoValidator : AbstractValidator<ResetPasswordRequestDto>
    {
        public ResetPasswordRequestDtoValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email không được để trống.")
                .EmailAddress().WithMessage("Email không hợp lệ.");

            RuleFor(x => x.Token)
                .NotEmpty().WithMessage("Token không được để trống.");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("Mật khẩu mới không được để trống.")
                .MinimumLength(6).WithMessage("Mật khẩu mới phải từ 6 ký tự trở lên.");
        }
    }
}