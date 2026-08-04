namespace DailyHelpService.Application.DTOs;

public record DailyHelpStaffDto(
    Guid Id, 
    string Name, 
    string MobileNumber, 
    Guid HelpTypeId, 
    string HelpTypeName, 
    string? AgencyName, 
    bool IsActive);