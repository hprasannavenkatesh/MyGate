namespace IdentityService.Domain;

public class UserProfileDto
{
    public Guid Id { get; set; }
    public string MobileNumber { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public bool IsMobileVerified { get; set; }
}