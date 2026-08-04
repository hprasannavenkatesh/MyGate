using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class SelectContextCommand : IRequest<string>
{
    public Guid UserId { get; set; }
    public Guid SocietyId { get; set; }
    public Guid FlatId { get; set; }
    public string MemberType { get; set; } = string.Empty; // "Owner", "Tenant", etc.

    public string Role { get; set; } = "Resident"; 
}