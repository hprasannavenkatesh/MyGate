using FluentValidation;

namespace AmenityService.Application.Features.Bookings.Commands.RejectBooking;

public class RejectBookingCommandValidator : AbstractValidator<RejectBookingCommand>
{
    public RejectBookingCommandValidator()
    {
        RuleFor(x => x.Id)
            .NotEmpty().WithMessage("Booking ID is required.");

        RuleFor(x => x.SocietyId)
            .NotEmpty().WithMessage("Society ID is required.");

        RuleFor(x => x.AdminUserId)
            .NotEmpty().WithMessage("Admin user ID is required.");

        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("Rejection reason is required.")
            .MaximumLength(300).WithMessage("Rejection reason cannot exceed 300 characters.");
    }
}