using MediatR;

namespace AmenityService.Application.Features.Amenities.Commands.CreateAmenity;

public record CreateAmenityCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public string? Location { get; init; }
    public bool IsBookable { get; init; } = true;
    public int SlotDurationMinutes { get; init; } = 60;
    public int MaxBookingsPerDayPerUser { get; init; } = 1;
    public int AdvanceBookingDaysAllowed { get; init; } = 7;
    public string OperatingHoursStart { get; init; } = "06:00";
    public string OperatingHoursEnd { get; init; } = "22:00";
}