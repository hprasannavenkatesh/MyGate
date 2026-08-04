using MediatR;

namespace DailyHelpService.Application.Features.Assignments.Commands.AssignStaff;

public record AssignStaffCommand : IRequest<Guid>
{
    public Guid StaffId { get; init; }
    public Guid FlatId { get; init; }
    public Guid SocietyId { get; init; }
    public string WorkingDays { get; init; } = "Mon,Tue,Wed,Thu,Fri,Sat";
    public string? InTime { get; init; }
    public string? OutTime { get; init; }
}