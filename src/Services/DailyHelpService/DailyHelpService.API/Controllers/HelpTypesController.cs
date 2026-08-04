using DailyHelpService.Application.DTOs;
using DailyHelpService.Application.Features.HelpTypes.Commands.CreateHelpType;
using DailyHelpService.Application.Features.HelpTypes.Queries.GetHelpTypesBySociety;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DailyHelpService.API.Controllers;

public class HelpTypesController : BaseController
{
    private readonly IMediator _mediator;
    public HelpTypesController(IMediator mediator) => _mediator = mediator;

    [HttpGet("society/{societyId}")]
    public async Task<ActionResult<IReadOnlyList<HelpTypeDto>>> GetBySociety(Guid societyId)
    {
        var result = await _mediator.Send(new GetHelpTypesBySocietyQuery { SocietyId = societyId });
        return Ok(result);
    }

    [HttpPost]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult<Guid>> Create([FromBody] CreateHelpTypeCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetBySociety), new { societyId = command.SocietyId }, id);
    }
}