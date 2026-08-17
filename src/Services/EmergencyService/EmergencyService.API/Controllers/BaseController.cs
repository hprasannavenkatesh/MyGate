using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencyService.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public abstract class BaseController : ControllerBase
{
    protected Guid UserId => Guid.TryParse(
        User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) 
        ? userId 
        : throw new UnauthorizedAccessException("Invalid user identifier in token.");

    protected string? Role => User.FindFirstValue(ClaimTypes.Role);
    protected bool IsAdmin => Role == "Admin";
}