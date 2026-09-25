using MediatR;


namespace VisitorService.Application.Features.Visitors.Commands;

public class ManualEntryCommand : IRequest<Unit>
{
    public Guid PreApprovalId { get; set; }
    public string Reason { get; set; } = string.Empty;
}