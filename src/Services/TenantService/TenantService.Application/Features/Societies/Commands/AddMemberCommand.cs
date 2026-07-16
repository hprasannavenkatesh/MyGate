using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public class AddMemberCommand : IRequest<Guid>
{
    public Guid SocietyId { get; set; }
    public Guid UserId { get; set; }       // The person being added
    public Guid FlatId { get; set; }       // The flat they are moving into
    public string MemberType { get; set; } = string.Empty; // "Owner", "Tenant", etc.
    public bool IsPrimary { get; set; } = false;
}