using VehicleService.Application.DTOs;
using VehicleService.Application.Features.ParkingSlots.Commands.AssignSlot;
using VehicleService.Application.Features.ParkingSlots.Commands.CreateSlot;
using VehicleService.Application.Features.ParkingSlots.Queries.GetSlotsBySociety;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace VehicleService.API.Controllers;

public class ParkingSlotsController : BaseController
{
    private readonly IMediator _mediator;
    public ParkingSlotsController(IMediator mediator) => _mediator = mediator;

    

    [HttpPut("assign")]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult> AssignSlot([FromBody] AssignSlotCommand command)
    {
        await _mediator.Send(command);
        return NoContent();
    }

     // NEW: Get Slots (Admin can see all, or filter by type/availability)
    [HttpGet]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IReadOnlyList<ParkingSlotDto>>> GetSlots(
        [FromQuery] Guid societyId, 
        [FromQuery] int? type = null, 
        [FromQuery] bool? isOccupied = null)
    {
        // Map nullable int to nullable VehicleType enum
        VehicleService.Domain.Enums.VehicleType? slotType = type.HasValue ? (VehicleService.Domain.Enums.VehicleType)type.Value : null;

        var result = await _mediator.Send(new GetSlotsBySocietyQuery 
        { 
            SocietyId = societyId, 
            Type = slotType, 
            IsOccupied = isOccupied 
        });
        return Ok(result);
    }

    // NEW: Create Slot (Admin only)
    [HttpPost]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Guid>> CreateSlot([FromBody] CreateSlotCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetSlots), new { societyId = command.SocietyId }, id);
    }

}