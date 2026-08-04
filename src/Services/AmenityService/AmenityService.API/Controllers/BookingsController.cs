using AmenityService.Application.DTOs;
using AmenityService.Application.Features.Bookings.Commands.ApproveBooking;
using AmenityService.Application.Features.Bookings.Commands.CancelBooking;
using AmenityService.Application.Features.Bookings.Commands.CreateBooking;
using AmenityService.Application.Features.Bookings.Commands.RejectBooking;
using AmenityService.Application.Features.Bookings.Queries.GetAvailableSlots;
using AmenityService.Application.Features.Bookings.Queries.GetBookingsByAmenity;
using AmenityService.Application.Features.Bookings.Queries.GetMyBookings;
using AmenityService.Application.Features.Bookings.Queries.GetPendingBookings;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AmenityService.API.Controllers;

public class BookingsController : BaseController
{
    private readonly IMediator _mediator;

    public BookingsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Get available time slots for an amenity on a specific date
    /// </summary>
    [HttpGet("slots/available")]
    public async Task<ActionResult<IReadOnlyList<AvailableSlotDto>>> GetAvailableSlots(
        [FromQuery] Guid amenityId, 
        [FromQuery] Guid societyId, 
        [FromQuery] string date)
    {
        var query = new GetAvailableSlotsQuery 
        { 
            AmenityId = amenityId, 
            SocietyId = societyId, 
            Date = date 
        };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// Get current user's bookings
    /// </summary>
    [HttpGet("my-bookings")]
    public async Task<ActionResult<IReadOnlyList<AmenityBookingDto>>> GetMyBookings(
        [FromQuery] Guid societyId)
    {
        var query = new GetMyBookingsQuery 
        { 
            UserId = UserId, 
            SocietyId = societyId 
        };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// Get all bookings for a specific amenity (Admin)
    /// </summary>
    [HttpGet("amenity/{amenityId}")]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IReadOnlyList<AmenityBookingDto>>> GetByAmenity(
        Guid amenityId, 
        [FromQuery] Guid societyId, 
        [FromQuery] string? date = null)
    {
        var query = new GetBookingsByAmenityQuery 
        { 
            AmenityId = amenityId, 
            SocietyId = societyId, 
            Date = date 
        };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// Get all pending bookings for a society (Admin)
    /// </summary>
    [HttpGet("pending")]
   // [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IReadOnlyList<AmenityBookingDto>>> GetPendingBookings(
        [FromQuery] Guid societyId)
    {
        var query = new GetPendingBookingsQuery { SocietyId = societyId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// Create a new booking
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<Guid>> Create([FromBody] CreateBookingCommand command)
    {
        // Override with authenticated user's ID
        command = command with { UserId = UserId };
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetMyBookings), new { societyId = command.SocietyId }, id);
    }

    /// <summary>
    /// Cancel own booking
    /// </summary>
    [HttpPut("{id}/cancel")]
    public async Task<ActionResult> Cancel(Guid id, [FromQuery] Guid societyId)
    {
        var command = new CancelBookingCommand 
        { 
            Id = id, 
            SocietyId = societyId, 
            UserId = UserId 
        };
        await _mediator.Send(command);
        return NoContent();
    }

    /// <summary>
    /// Approve a booking (Admin only)
    /// </summary>
    [HttpPut("{id}/approve")]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult> Approve(Guid id, [FromQuery] Guid societyId)
    {
        var command = new ApproveBookingCommand 
        { 
            Id = id, 
            SocietyId = societyId, 
            AdminUserId = UserId 
        };
        await _mediator.Send(command);
        return NoContent();
    }

    /// <summary>
    /// Reject a booking (Admin only)
    /// </summary>
    [HttpPut("{id}/reject")]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult> Reject(
        Guid id, 
        [FromQuery] Guid societyId, 
        [FromBody] RejectBookingRequest request)
    {
        var command = new RejectBookingCommand 
        { 
            Id = id, 
            SocietyId = societyId, 
            AdminUserId = UserId, 
            Reason = request.Reason 
        };
        await _mediator.Send(command);
        return NoContent();
    }
}

// Request model for reject endpoint (not a MediatR command, just API payload)
public record RejectBookingRequest(string Reason);