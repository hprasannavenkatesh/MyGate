using VehicleService.Application.DTOs;
using VehicleService.Application.Features.Vehicles.Commands.RegisterVehicle;
using VehicleService.Application.Features.Vehicles.Queries.GetMyVehicles;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace VehicleService.API.Controllers;

public class VehiclesController : BaseController
{
    private readonly IMediator _mediator;
    public VehiclesController(IMediator mediator) => _mediator = mediator;

    [HttpGet("my-vehicles")]
    public async Task<ActionResult<IReadOnlyList<VehicleDto>>> GetMyVehicles([FromQuery] Guid societyId)
    {
        var result = await _mediator.Send(new GetMyVehiclesQuery { SocietyId = societyId, UserId = UserId });
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<Guid>> Register([FromBody] RegisterVehicleCommand command)
    {
        // Override OwnerId with actual JWT User ID
        command = command with { OwnerId = UserId };
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetMyVehicles), new { societyId = command.SocietyId }, id);
    }
}