namespace DailyHelpService.Application.DTOs;

public record DailyHelpAssignmentDto(
    Guid Id,
    Guid StaffId,
    string StaffName,
    string StaffMobile,
    string HelpTypeName,
    Guid FlatId,
    string WorkingDays,
    string? InTime,
    string? OutTime,
    bool IsActive);