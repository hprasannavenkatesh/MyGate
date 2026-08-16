using DirectoryService.Application.DTOs;
using DirectoryService.Application.Features.Directory.Commands.AddEntry;
using DirectoryService.Application.Features.Directory.Commands.DeleteEntry;
using DirectoryService.Application.Features.Directory.Queries.GetDirectory;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DirectoryService.API.Controllers;

public class DirectoryController : BaseController
{
    private readonly IMediator _mediator;
    public DirectoryController(IMediator mediator) => _mediator = mediator;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<DirectoryEntryDto>>> Get([FromQuery] Guid societyId, [FromQuery] string? category = null, [FromQuery] string? search = null)
    {
        var result = await _mediator.Send(new GetDirectoryQuery { SocietyId = societyId, Category = category, Search = search });
        return Ok(result);
    }

    [HttpPost]
   //[Authorize(Roles = "Admin")]
    public async Task<ActionResult<Guid>> Add([FromBody] AddEntryCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(Get), new { societyId = command.SocietyId }, id);
    }

    [HttpDelete("{id}")]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult> Delete(Guid id, [FromQuery] Guid societyId)
    {
        var entry = await _mediator.Send(new DeleteEntryCommand { Id = id, SocietyId = societyId });
        return NoContent();
    }
}