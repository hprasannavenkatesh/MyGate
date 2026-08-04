using FluentValidation;

namespace AmenityService.Application.Features.Amenities.Commands.UpdateAmenity;

public class UpdateAmenityCommandValidator : AbstractValidator<UpdateAmenityCommand>
{
    public UpdateAmenityCommandValidator()
    {
        RuleFor(x => x.Id)
            .NotEmpty().WithMessage("Amenity ID is required.");

        RuleFor(x => x.SocietyId)
            .NotEmpty().WithMessage("Society ID is required.");

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Amenity name is required.")
            .MaximumLength(100).WithMessage("Amenity name cannot exceed 100 characters.");

        RuleFor(x => x.Description)
            .MaximumLength(500).WithMessage("Description cannot exceed 500 characters.");

        RuleFor(x => x.Location)
            .MaximumLength(200).WithMessage("Location cannot exceed 200 characters.");

        RuleFor(x => x.SlotDurationMinutes)
            .InclusiveBetween(15, 480).WithMessage("Slot duration must be between 15 and 480 minutes.");

        RuleFor(x => x.MaxBookingsPerDayPerUser)
            .GreaterThanOrEqualTo(1).WithMessage("Max bookings per day must be at least 1.");

        RuleFor(x => x.AdvanceBookingDaysAllowed)
            .InclusiveBetween(0, 30).WithMessage("Advance booking days must be between 0 and 30.");

        RuleFor(x => x.OperatingHoursStart)
            .Matches(@"^([01]?[0-9]|2[0-3]):[0-5][0-9]$")
            .WithMessage("Invalid operating hours start format. Use HH:mm.");

        RuleFor(x => x.OperatingHoursEnd)
            .Matches(@"^([01]?[0-9]|2[0-3]):[0-5][0-9]$")
            .WithMessage("Invalid operating hours end format. Use HH:mm.");

        RuleFor(x => x)
            .Custom((cmd, context) =>
            {
                var start = TimeOnly.Parse(cmd.OperatingHoursStart);
                var end = TimeOnly.Parse(cmd.OperatingHoursEnd);
                if (start >= end)
                    context.AddFailure("Operating hours start must be before end.");
            });
    }
}