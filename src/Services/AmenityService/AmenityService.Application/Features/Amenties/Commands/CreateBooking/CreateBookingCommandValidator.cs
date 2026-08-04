using FluentValidation;

namespace AmenityService.Application.Features.Bookings.Commands.CreateBooking;

public class CreateBookingCommandValidator : AbstractValidator<CreateBookingCommand>
{
    public CreateBookingCommandValidator()
    {
        RuleFor(x => x.AmenityId)
            .NotEmpty().WithMessage("Amenity ID is required.");

        RuleFor(x => x.SocietyId)
            .NotEmpty().WithMessage("Society ID is required.");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required.");

        RuleFor(x => x.FlatNumber)
            .NotEmpty().WithMessage("Flat number is required.")
            .MaximumLength(20).WithMessage("Flat number cannot exceed 20 characters.");

        RuleFor(x => x.BookingDate)
            .NotEmpty().WithMessage("Booking date is required.")
            .Matches(@"^\d{4}-\d{2}-\d{2}$").WithMessage("Booking date must be in YYYY-MM-DD format.")
            .Must(BeValidDate).WithMessage("Invalid booking date.");

        RuleFor(x => x.StartTime)
            .NotEmpty().WithMessage("Start time is required.")
            .Matches(@"^([01]?[0-9]|2[0-3]):[0-5][0-9]$")
            .WithMessage("Start time must be in HH:mm format.");

        RuleFor(x => x.EndTime)
            .NotEmpty().WithMessage("End time is required.")
            .Matches(@"^([01]?[0-9]|2[0-3]):[0-5][0-9]$")
            .WithMessage("End time must be in HH:mm format.");

        RuleFor(x => x.Notes)
            .MaximumLength(500).WithMessage("Notes cannot exceed 500 characters.");

        RuleFor(x => x)
            .Custom((cmd, context) =>
            {
                if (!TimeOnly.TryParse(cmd.StartTime, out var start) || 
                    !TimeOnly.TryParse(cmd.EndTime, out var end))
                    return;

                if (start >= end)
                    context.AddFailure("Start time must be before end time.");
            });
    }

    private static bool BeValidDate(string date)
    {
        return DateOnly.TryParseExact(date, "yyyy-MM-dd", out _);
    }
}