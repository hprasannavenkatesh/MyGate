using System.Security.Claims; // CRITICAL FOR ClaimTypes
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using HelpdeskService.Application.Features.Tickets.Commands;
using HelpdeskService.Application.Features.Tickets.Queries;
using HelpdeskService.Application.Features.Admin;

namespace HelpdeskService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TicketsController : BaseController
{
    private readonly IMediator _mediator;
    public TicketsController(IMediator mediator) => _mediator = mediator;

   
    [HttpPost("raise")]
    public async Task<IActionResult> RaiseTicket([FromBody] RaiseTicketCommand command)
    {
      command.CreatedByUserId = GetUserId(); // Injects the real ID!
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(RaiseTicket), new { id }, new { Id = id });
    }

    [HttpGet("my-tickets")]
    public async Task<IActionResult> GetMyTickets([FromQuery] Guid flatId)
    {
        var query = new GetMyTicketsQuery { FlatId = flatId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

     // NEW ENDPOINTS:

    [HttpGet("{ticketId}")]
    public async Task<IActionResult> GetTicketDetails(Guid ticketId)
    {
        var query = new GetTicketDetailsQuery { TicketId = ticketId };
        var result = await _mediator.Send(query);
        return result == null ? NotFound() : Ok(result);
    }

    [HttpPost("{ticketId}/comments")]
    public async Task<IActionResult> AddComment(Guid ticketId, [FromBody] AddCommentCommand command)
    {
     command.TicketId = ticketId;
        command.UserId = GetUserId(); // Injects the real ID!
        await _mediator.Send(command);
        return Ok();
    }

    [HttpPut("{ticketId}/status")]
     [Authorize(Roles = "Admin")] // <--- THE MAGIC WORDS = ADMIN ONLY ENDPOINTS
    public async Task<IActionResult> UpdateStatus(Guid ticketId, [FromBody] UpdateTicketStatusCommand command)
    {
        command.TicketId = ticketId;
        await _mediator.Send(command);
        return NoContent();
    }
}