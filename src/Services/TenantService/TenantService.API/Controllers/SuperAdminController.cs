using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using TenantService.Application.Features.Societies.Commands;
using TenantService.Application.Features.Societies.Queries;

namespace TenantService.API.Controllers;

[ApiController]
[Route("api/superadmin")]
[Authorize(Roles = "SuperAdmin")] // 🔒 LOCKED DOWN: Only SuperAdmins can hit this controller
public class SuperAdminController : ControllerBase
{
    private readonly IMediator _mediator;

    public SuperAdminController(IMediator mediator)
    {
        _mediator = mediator;
    }

    // ==========================================
    // LAYER 2: CROSS-SOCIETY ENDPOINTS
    // ==========================================

    /// <summary>
    /// Gets ALL societies. Used by the SuperAdmin Society Picker in React.
    /// </summary>
    [HttpGet("societies")]
      [Authorize(Roles = "SuperAdmin")] // FIXED: Was missing — anyone could list all societies
    public async Task<IActionResult> GetAllSocieties()
    {
        var result = await _mediator.Send(new GetAllSocietiesQuery());
        return Ok(result);
    }

    /// <summary>
    /// Creates a brand new society. SuperAdmin only.
    /// </summary>
    [HttpPost("societies")]
     [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> CreateSociety([FromBody] CreateSocietyCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetAllSocieties), new { id }, new { Id = id });
    }

    /// <summary>
    /// Deletes a society and all its associated data (Blocks, Flats, Members).
    /// </summary>
    [HttpDelete("societies/{id}")]
     [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> DeleteSociety(Guid id)
    {
        // We will create this command next
        await _mediator.Send(new DeleteSocietyCommand { SocietyId = id });
        return NoContent();
    }
}