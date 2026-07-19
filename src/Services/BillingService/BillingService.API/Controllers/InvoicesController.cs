using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using BillingService.Application.Features.Invoices.Commands;
using BillingService.Application.Features.Invoices.Queries;

namespace BillingService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class InvoicesController : ControllerBase
{
    private readonly IMediator _mediator;
    public InvoicesController(IMediator mediator) => _mediator = mediator;

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateInvoiceCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(Generate), new { id }, new { Id = id });
    }

    [HttpGet("my-dues")]
    public async Task<IActionResult> GetMyDues([FromQuery] Guid flatId)
    {
        var result = await _mediator.Send(new GetMyDuesQuery { FlatId = flatId });
        return Ok(result);
    }
}