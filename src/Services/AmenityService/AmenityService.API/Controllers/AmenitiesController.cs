using Microsoft.AspNetCore.Authorization;
using AmenityService.Application.DTOs;
using MediatR;
using AmenityService.Application.Features.Amenities.Commands.CreateAmenity;
using AmenityService.Application.Features.Amenities.Commands.DeleteAmenity;
using AmenityService.Application.Features.Amenities.Commands.UpdateAmenity;
using AmenityService.Application.Features.Amenities.Queries.GetAmenityById;
using AmenityService.Application.Features.Amenities.Queries.GetAmenitiesBySociety;
using Microsoft.AspNetCore.Mvc;

namespace AmenityService.API.Controllers;

public class AmenitiesController : BaseController
{
    private readonly IMediator _mediator;

    public AmenitiesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Get all amenities for a society
    /// </summary>
    [HttpGet("society/{societyId}")]
    public async Task<ActionResult<IReadOnlyList<AmenityDto>>> GetBySociety(
        Guid societyId, 
        [FromQuery] bool activeOnly = true)
    {
        var query = new GetAmenitiesBySocietyQuery 
        { 
            SocietyId = societyId, 
            ActiveOnly = activeOnly 
        };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// Get a specific amenity by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<AmenityDto>> GetById(Guid id, [FromQuery] Guid societyId)
    {
        var query = new GetAmenityByIdQuery { Id = id, SocietyId = societyId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// Create a new amenity (Admin only)
    /// </summary>
    [HttpPost]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult<Guid>> Create([FromBody] CreateAmenityCommand command)
    {
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetById), new { id, societyId = command.SocietyId }, id);
    }

    /// <summary>
    /// Update an existing amenity (Admin only)
    /// </summary>
    [HttpPut("{id}")]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult> Update(Guid id, [FromBody] UpdateAmenityCommand command)
    {
        if (id != command.Id)
            return BadRequest("ID in route must match ID in body.");

        await _mediator.Send(command);
        return NoContent();
    }

    /// <summary>
    /// Deactivate an amenity (Admin only - soft delete)
    /// </summary>
    [HttpDelete("{id}")]
    //[Authorize(Roles = "Admin")]
    public async Task<ActionResult> Delete(Guid id, [FromQuery] Guid societyId)
    {
        var command = new DeleteAmenityCommand { Id = id, SocietyId = societyId };
        await _mediator.Send(command);
        return NoContent();
    }
}