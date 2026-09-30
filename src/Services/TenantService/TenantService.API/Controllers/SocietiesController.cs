using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using TenantService.Application.Features.Societies.Commands;
using TenantService.Application.Features.Societies.Queries;

namespace TenantService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SocietiesController : ControllerBase
{
    private readonly IMediator _mediator;

    public SocietiesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    // GET /api/societies/my-societies?userId=xxxxx
    [Authorize]
    [HttpGet("my-societies")]
    public async Task<IActionResult> GetMySocieties([FromQuery] Guid userId)
    {
        var query = new GetUserSocietiesQuery { UserId = userId };
        var result = await _mediator.Send(query);
        
        return Ok(result);
    }

     [HttpPost("create")]
     [Authorize(Roles = "Admin,SuperAdmin")]
    public async Task<IActionResult> CreateSociety([FromBody] CreateSocietyCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateSociety), new { id }, new { Id = id });
    }

    [HttpPost("create-block")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public async Task<IActionResult> CreateBlock([FromBody] CreateBlockCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateBlock), new { id }, new { Id = id });
    }

    [HttpPost("create-flat")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public async Task<IActionResult> CreateFlat([FromBody] CreateFlatCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateFlat), new { id }, new { Id = id });
    }

    [HttpPost("add-member")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public async Task<IActionResult> AddMember([FromBody] AddMemberCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(AddMember), new { id }, new { Id = id });
    }

    // --- NEW READ ENDPOINTS FOR ADMIN PORTAL ---

    [HttpGet] // GET /api/societies
    [Authorize(Roles = "SuperAdmin")] // Only SuperAdmin can view all societies
    public async Task<IActionResult> GetAll()
    {
        var result = await _mediator.Send(new GetAllSocietiesQuery());
        return Ok(result);
    }

    [HttpGet("{id}")] // GET /api/societies/{guid}
    [Authorize(Roles = "SuperAdmin")] // Only SuperAdmin can view society details
    public async Task<IActionResult> GetById(Guid id)
    {
        var result = await _mediator.Send(new GetSocietyByIdQuery { Id = id });
        if (result == null) return NotFound();
        return Ok(result);
    }

    [HttpGet("{societyId}/blocks")] // GET /api/societies/{guid}/blocks
    [Authorize]
    public async Task<IActionResult> GetBlocks(Guid societyId)
    {
        var result = await _mediator.Send(new GetBlocksBySocietyQuery { SocietyId = societyId });
        return Ok(result);
    }

    [HttpGet("blocks/{blockId}/flats")] // GET /api/societies/blocks/{guid}/flats
    [Authorize]
    public async Task<IActionResult> GetFlats(Guid blockId)
    {
        var result = await _mediator.Send(new GetFlatsByBlockQuery { BlockId = blockId });
        return Ok(result);
    }
}