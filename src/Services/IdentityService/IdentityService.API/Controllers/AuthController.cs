using IdentityService.Application.Features.Auth.Commands;
using IdentityService.Application.Features.Auth.Queries;
using Microsoft.AspNetCore.Authorization;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace IdentityService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("register")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public async Task<IActionResult> Register([FromBody] RegisterUserCommand command)
    {
        // Send the command to MediatR, which sends it to our Handler
        var userId = await _mediator.Send(command);

        // Return the newly created User ID to the Flutter app
        return CreatedAtAction(nameof(Register), new { id = userId }, new { Id = userId });
    }

    // NEW: LOGIN ENDPOINT
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginQuery query)
    {
        var token = await _mediator.Send(query);
        return Ok(new { Token = token });
    }

    [HttpPost("select-context")]
    public async Task<IActionResult> SelectContext([FromBody] SelectContextCommand command)
    {
        var token = await _mediator.Send(command);
        return Ok(new { Token = token });
    }

    [Authorize]
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile([FromQuery] Guid userId)
    {
        var query = new GetProfileQuery { UserId = userId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }
    [Authorize]
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileCommand command)
    {
        await _mediator.Send(command);
        return NoContent(); // 204 No Content is standard for a successful update
    }

    [HttpPost("request-otp")]
    public async Task<IActionResult> RequestOtp([FromBody] RequestOtpCommand command)
    {
        // This just returns OK. The real OTP is printed in the terminal!
        await _mediator.Send(command);
        return Ok(new { Message = "If you are registered, an OTP has been sent." });
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpCommand command)
    {
        var token = await _mediator.Send(command);
        return Ok(new { Token = token });
    }

    // Add this method to the existing AuthController class:

    [HttpGet("lookup/{mobileNumber}")]
    [Authorize]
    public async Task<IActionResult> LookupUser(string mobileNumber)
    {
        var query = new LookupUserByMobileQuery { MobileNumber = mobileNumber };
        var result = await _mediator.Send(query);

        if (result is null)
            return NotFound(new { Message = "No user found with this mobile number." });

        return Ok(result);
    }

    // ✅ ADD THIS NEW ENDPOINT
    [HttpPost("create-guard")]
    [Authorize(Roles = "Admin,SuperAdmin")] // Only Admins can create Guards
    public async Task<IActionResult> CreateGuard([FromBody] RegisterUserCommand command)
    {
        // FORCE security-sensitive fields regardless of what the JSON payload contained
        command.Role = "Guard";
        command.Password = "Guard@123";
        var id = await _mediator.Send(command);
        return Ok(new { Id = id });
    }



}