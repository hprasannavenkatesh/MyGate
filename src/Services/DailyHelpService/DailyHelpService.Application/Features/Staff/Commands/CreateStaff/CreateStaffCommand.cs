using MediatR;

namespace DailyHelpService.Application.Features.Staff.Commands.CreateStaff;

public record CreateStaffCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string MobileNumber { get; init; } = string.Empty;
    public Guid HelpTypeId { get; init; }
    public string? AgencyName { get; init; }
}