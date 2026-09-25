using MediatR;

namespace VisitorService.Application.Features.Visitors.Commands;

public class MarkVisitorExitCommand : IRequest<Unit>
{
   // public Guid LogId { get; set; }
      public Guid PreApprovalId { get; set; }
}