namespace AmenityService.Application.DTOs;

public record AmenityDto(
    Guid Id,
    Guid SocietyId,
    string Name,
    string? Description,
    string? Location,
    bool IsActive,
    bool IsBookable,
    int SlotDurationMinutes,
    int MaxBookingsPerDayPerUser,
    int AdvanceBookingDaysAllowed,
    string OperatingHoursStart,
    string OperatingHoursEnd,
    DateTimeOffset CreatedAt);