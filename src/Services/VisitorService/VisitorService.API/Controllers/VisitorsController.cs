using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using VisitorService.Domain.Interfaces;
using VisitorService.Infrastructure.Repositories;
using VisitorService.Application.Features.Visitors.Commands;

namespace VisitorService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Locked down! Needs JWT
public class VisitorsController : ControllerBase
{
    private readonly IMediator _mediator;

    public VisitorsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("pre-approve")]
    public async Task<IActionResult> PreApprove([FromBody] PreApproveVisitorCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(PreApprove), new { id }, new { Id = id });
    }

        [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyVisitorOtpCommand command)
    {
        var id = await _mediator.Send(command);
        return Ok(new { Message = "Visitor allowed inside.", VisitorId = id });
    }
      [HttpPost("mark-exit")]
    public async Task<IActionResult> MarkExit([FromBody] MarkVisitorExitCommand command)
    {
        await _mediator.Send(command);
        return Ok(); // 204 No Content
    }
}