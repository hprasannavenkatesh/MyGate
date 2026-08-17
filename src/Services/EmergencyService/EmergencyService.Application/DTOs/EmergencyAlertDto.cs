using EmergencyService.Domain.Enums;

namespace EmergencyService.Application.DTOs;

public record EmergencyAlertDto(
    Guid Id,
    EmergencyType Type,
    string? Description,
    AlertStatus Status,
    DateTimeOffset TriggeredAt);