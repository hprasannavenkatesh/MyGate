using EmergencyService.Application.DTOs;
using EmergencyService.Application.Features.Alerts.Commands.ResolveAlert;
using EmergencyService.Application.Features.Alerts.Commands.TriggerPanic;
using EmergencyService.Application.Features.Alerts.Queries.GetActiveAlerts;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace EmergencyService.API.Controllers // MUST MATCH EXACTLY
{
    public class EmergencyController : BaseController
    {
        private readonly IMediator _mediator;
        public EmergencyController(IMediator mediator) => _mediator = mediator;

        [HttpPost("trigger")]
        public async Task<ActionResult<Guid>> TriggerPanic([FromBody] TriggerPanicCommand command)
        {
            var id = await _mediator.Send(command);
            return Ok(id); 
        }

        [HttpGet("active")]
        public async Task<ActionResult<IReadOnlyList<EmergencyAlertDto>>> GetActiveAlerts([FromQuery] Guid societyId)
        {
            var result = await _mediator.Send(new GetActiveAlertsQuery { SocietyId = societyId });
            return Ok(result);
        }

        [HttpPut("resolve/{alertId}")]
        public async Task<ActionResult> ResolveAlert(Guid alertId, [FromQuery] Guid societyId)
        {
            await _mediator.Send(new ResolveAlertCommand { AlertId = alertId, SocietyId = societyId });
            return NoContent();
        }
    }
}