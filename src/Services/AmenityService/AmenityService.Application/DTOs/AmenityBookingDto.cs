using AmenityService.Domain.Enums;

namespace AmenityService.Application.DTOs;

public record AmenityBookingDto(
    Guid Id,
    Guid AmenityId,
    string AmenityName,
    Guid SocietyId,
    Guid UserId,
    string FlatNumber,
    DateOnly BookingDate,
    string StartTime,
    string EndTime,
    BookingStatus Status,
    string? Notes,
    Guid? ApprovedBy,
    DateTimeOffset? ApprovedAt,
    string? RejectionReason,
    DateTimeOffset CreatedAt);