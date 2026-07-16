using MediatR;

namespace VisitorService.Application.Features.Visitors.Commands;

public class VerifyVisitorOtpCommand : IRequest<Guid>
{
    public Guid PreApprovalId { get; set; } // The ID of the pre-approved visitor
    public string Otp { get; set; } = string.Empty;
}