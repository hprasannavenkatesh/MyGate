namespace TenantService.Domain;

public class UserSocietyDto
{
    public Guid SocietyId { get; set; }
    public string SocietyName { get; set; } = string.Empty;
    public Guid FlatId { get; set; }
    public string FlatNumber { get; set; } = string.Empty;
    public string BlockName { get; set; } = string.Empty;
    public string MemberType { get; set; } = string.Empty; // "Owner", "Tenant", etc.
}