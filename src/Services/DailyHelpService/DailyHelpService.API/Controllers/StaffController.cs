using DailyHelpService.Application.DTOs;
using DailyHelpService.Application.Features.Staff.Commands.CreateStaff;
using DailyHelpService.Application.Features.Staff.Queries.GetStaffBySociety;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DailyHelpService.API.Controllers;

public class StaffController : BaseController
{
    private readonly IMediator _mediator;
    public StaffController(IMediator mediator) => _mediator = mediator;

    [HttpGet("society/{societyId}")]
    public async Task<ActionResult<IReadOnlyList<DailyHelpStaffDto>>> GetBySociety(Guid societyId, [FromQuery] Guid? helpTypeId = null)
    {
        var result = await _mediator.Send(new GetStaffBySocietyQuery { SocietyId = societyId, HelpTypeId = helpTypeId });
        return Ok(result);
    }

    [HttpPost]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult<Guid>> Create([FromBody] CreateStaffCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetBySociety), new { societyId = command.SocietyId }, id);
    }
}