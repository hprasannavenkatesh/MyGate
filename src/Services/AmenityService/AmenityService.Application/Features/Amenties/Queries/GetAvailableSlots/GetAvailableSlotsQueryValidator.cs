using FluentValidation;

namespace AmenityService.Application.Features.Bookings.Queries.GetAvailableSlots;

public class GetAvailableSlotsQueryValidator : AbstractValidator<GetAvailableSlotsQuery>
{
    public GetAvailableSlotsQueryValidator()
    {
        RuleFor(x => x.AmenityId)
            .NotEmpty().WithMessage("Amenity ID is required.");

        RuleFor(x => x.SocietyId)
            .NotEmpty().WithMessage("Society ID is required.");

        RuleFor(x => x.Date)
            .NotEmpty().WithMessage("Date is required.")
            .Matches(@"^\d{4}-\d{2}-\d{2}$").WithMessage("Date must be in YYYY-MM-DD format.")
            .Must(BeValidDate).WithMessage("Invalid date.");
    }

    private static bool BeValidDate(string date)
    {
        return DateOnly.TryParseExact(date, "yyyy-MM-dd", out _);
    }
}