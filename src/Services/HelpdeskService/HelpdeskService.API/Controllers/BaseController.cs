using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace HelpdeskService.API.Controllers;

[ApiController]
public abstract class BaseController : ControllerBase
{
    protected Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
            ?? User.FindFirst("sub")?.Value;
            
        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            throw new UnauthorizedAccessException("Valid User ID not found in token.");
            
        return userId;
    }
}