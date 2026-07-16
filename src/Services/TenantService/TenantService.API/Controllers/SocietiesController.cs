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
    public async Task<IActionResult> CreateSociety([FromBody] CreateSocietyCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateSociety), new { id }, new { Id = id });
    }

    [HttpPost("create-block")]
    public async Task<IActionResult> CreateBlock([FromBody] CreateBlockCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateBlock), new { id }, new { Id = id });
    }

    [HttpPost("create-flat")]
    public async Task<IActionResult> CreateFlat([FromBody] CreateFlatCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateFlat), new { id }, new { Id = id });
    }

    [HttpPost("add-member")]
    public async Task<IActionResult> AddMember([FromBody] AddMemberCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(AddMember), new { id }, new { Id = id });
    }
}