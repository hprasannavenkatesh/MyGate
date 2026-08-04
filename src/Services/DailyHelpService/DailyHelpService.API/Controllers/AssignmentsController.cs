using DailyHelpService.Application.DTOs;
using DailyHelpService.Application.Features.Assignments.Commands.AssignStaff;
using DailyHelpService.Application.Features.Assignments.Queries.GetMyAssignments;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DailyHelpService.API.Controllers;

public class AssignmentsController : BaseController
{
    private readonly IMediator _mediator;
    public AssignmentsController(IMediator mediator) => _mediator = mediator;

    [HttpGet("my-help")]
    public async Task<ActionResult<IReadOnlyList<DailyHelpAssignmentDto>>> GetMyHelp([FromQuery] Guid flatId)
    {
        var result = await _mediator.Send(new GetMyAssignmentsQuery { FlatId = flatId });
        return Ok(result);
    }

    [HttpPost]
  //  [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Guid>> Assign([FromBody] AssignStaffCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetMyHelp), new { flatId = command.FlatId }, id);
    }

    [HttpDelete("{id}")]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult> RemoveAssignment(Guid id)
    {
        // TODO: Implement removal via MediatR
        return NoContent();
    }
}