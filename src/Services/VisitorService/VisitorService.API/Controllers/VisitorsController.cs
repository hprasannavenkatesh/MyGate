using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using VisitorService.Domain.Interfaces;
using VisitorService.Infrastructure.Repositories;
using VisitorService.Application.Features.Visitors.Commands;
using VisitorService.Application.Features.Visitors.Queries; // For GetMyVisitorsQuery
using VisitorService.Domain.Entities;                     // For PreApprovedVisitor

namespace VisitorService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Locked down! Needs JWT
public class VisitorsController : BaseController
{
    private readonly IMediator _mediator;

    public VisitorsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    // ADMIN: Get ALL! Get all visitors for a society
    [HttpGet("society/{societyId}")]
    public async Task<IActionResult> GetSocietyVisitors(Guid societyId)
    {
        var query = new GetSocietyVisitorsQuery { SocietyId = societyId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    [HttpPost("pre-approve")]
    public async Task<IActionResult> PreApprove([FromBody] PreApproveVisitorCommand command)
    {
        /*
      // The 'UserId' comes from your BaseController, which reads the JWT
      command.InvitedByUserId = GetUserId(); // Injects the real ID!
      var id = await _mediator.Send(command);
      return Ok(new { Id = id });
     // return CreatedAtAction(nameof(PreApprove), new { id }, new { Id = id });
     */
        command.InvitedByUserId = GetUserId();
        var result = await _mediator.Send(command);
        // CHANGED: Return OTP along with ID so frontend can display it
        return Ok(new { Id = result.Id, Otp = result.Otp });
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

    //RESIDENT: Get my visitors
    [HttpGet("my-visitors")]
    public async Task<IActionResult> GetMyVisitors([FromQuery] Guid inviterId)
    {
        var query = new GetMyVisitorsQuery { InviterId = inviterId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    // ADMIN: Manual entry override (no OTP)
    [HttpPost("{id}/manual-entry")]
    public async Task<IActionResult> ManualEntry(Guid id, [FromBody] ManualEntryCommand command)
    {
        command.PreApprovalId = id;
        await _mediator.Send(command);
        return Ok(new { Message = "Visitor manually marked as entered." });
    }

    // NEW: Regenerate OTP for an existing Pending visitor
    [HttpPost("{id}/regenerate-otp")]
    public async Task<IActionResult> RegenerateOtp(Guid id)
    {
        var command = new RegenerateOtpCommand { PreApprovalId = id };
        var result = await _mediator.Send(command);
        return Ok(new { Otp = result.Otp, ExpiresAt = result.ExpiresAt });
    }
}