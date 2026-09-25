using MediatR;

namespace VisitorService.Application.Features.Visitors.Commands;

public record RegenerateOtpResult(string Otp, DateTime ExpiresAt);

public class RegenerateOtpCommand : IRequest<RegenerateOtpResult>
{
    public Guid PreApprovalId { get; set; }
}