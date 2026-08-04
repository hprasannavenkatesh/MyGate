using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using IdentityService.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace IdentityService.Infrastructure.Services;

public class TokenService : ITokenService
{
    private readonly IConfiguration _config;

    public TokenService(IConfiguration config)
    {
        _config = config;
    }

    public string GenerateToken(Guid userId, string mobileNumber, string fullName, 
        Guid? societyId = null, Guid? flatId = null, string? memberType = null,string? role=null)
    {
         // 1. Get the secret key safely. If it's missing in appsettings, throw a clear error!
        var keyString = _config["Jwt:Key"] 
            ?? throw new InvalidOperationException("JWT Key is missing from configuration.");
        var key = Encoding.UTF8.GetBytes(keyString);

        // 2. Create the "Credentials" to sign the token
        var signingCredentials = new SigningCredentials(
            new SymmetricSecurityKey(key), 
            SecurityAlgorithms.HmacSha256);

        // 3. Define what information (Claims) lives INSIDE the wristband
       var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()), // Sub = Subject (User ID)
            new Claim(JwtRegisteredClaimNames.UniqueName, mobileNumber),
            new Claim("FullName", fullName)
            // Later we will add SocietyId and FlatId here!
        };
         // IF society/flat data is provided, add it to the wristband!
        if (societyId.HasValue) claims.Add(new Claim("SocietyId", societyId.Value.ToString()));
        if (flatId.HasValue) claims.Add(new Claim("FlatId", flatId.Value.ToString()));
        if (!string.IsNullOrEmpty(memberType)) claims.Add(new Claim("MemberType", memberType));

        if (!string.IsNullOrEmpty(role)) 
            claims.Add(new Claim(ClaimTypes.Role, role));

        // 4. Build the actual token
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(Convert.ToDouble(_config["Jwt:ExpiryInMinutes"])),
            signingCredentials: signingCredentials
        );

        // 5. Convert it to a string and hand it back
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}