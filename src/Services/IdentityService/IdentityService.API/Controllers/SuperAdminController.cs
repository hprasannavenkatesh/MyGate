using Microsoft.AspNetCore.Mvc;
using System.Net.Http.Headers;
using System.Text.Json;
using IdentityService.Domain.Interfaces;

namespace IdentityService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SuperAdminController : ControllerBase
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IUserRepository _userRepository;

    public SuperAdminController(IHttpClientFactory httpClientFactory, IUserRepository userRepository)
    {
        _httpClientFactory = httpClientFactory;
        _userRepository = userRepository;
    }

    [HttpGet("societies")]
    public async Task<IActionResult> GetAllSocieties()
    {
        try
        {
            // 1. Extract Token from Header safely
            var authHeader = HttpContext.Request.Headers["Authorization"].ToString();
            
            if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                return Unauthorized("Token is missing.");
            }

            var token = authHeader.Substring("Bearer ".Length).Trim();
            var handler =  new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
            
            if (!handler.CanReadToken(token))
            {
                return Unauthorized("Invalid token format.");
            }

            var jwtToken = handler.ReadJwtToken(token);
            var userIdClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == "sub")?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized("Invalid user identifier in token.");
            }

            // 2. SECURITY CHECK: Look up the user in the DB
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) return Forbid("User not found.");

            // Only allow if their mobile number is our designated SuperAdmin number
           if (user.MobileNumber != "0000000000") 
            {
                return Forbid("You do not have permission to view all societies.");
            }

            // 3. Proxy the request to TenantService (Port 5104)
            var client = _httpClientFactory.CreateClient("TenantService");
            
            // We do NOT pass the Bearer token here, because TenantService's 
            // SuperAdmin endpoint is an internal open endpoint.
            var response = await client.GetAsync("http://localhost:5104/api/superadmin/societies");

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"❌ ERROR from TenantService: {response.StatusCode} - {errorContent}");
                return StatusCode((int)response.StatusCode, "Failed to fetch societies from TenantService.");
            }

            var content = await response.Content.ReadAsStringAsync();
            var societies = JsonSerializer.Deserialize<object>(content, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            return Ok(societies);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ FATAL ERROR in SuperAdminController: {ex.Message}");
            return StatusCode(500, "An internal error occurred.");
        }
    }
}