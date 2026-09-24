using MediatR;

namespace VisitorService.Application.Features.Visitors.Commands;

public class PreApproveVisitorCommand : IRequest<Guid>
{
    public Guid SocietyId { get; set; }
    public Guid FlatId { get; set; }
    public string VisitorName { get; set; } = string.Empty;
    public string VisitorMobile { get; set; } = string.Empty;
    public DateTime ExpectedDate { get; set; }
    public TimeSpan? ExpectedTime { get; set; }
    public string? Purpose { get; set; }
    public Guid InvitedByUserId { get; set; } 
}