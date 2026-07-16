namespace IdentityService.Domain.Interfaces;

public interface ITokenService
{
     // We added optional parameters! If they are null, it makes a Basic Token. If they have data, it makes a Fat Token.
    string GenerateToken(Guid userId, string mobileNumber, string fullName, 
        Guid? societyId = null, Guid? flatId = null, string? memberType = null);
}