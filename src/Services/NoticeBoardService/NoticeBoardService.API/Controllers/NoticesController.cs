using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MediatR;
using NoticeBoardService.Application.Features.Notices.Commands;
using NoticeBoardService.Application.Features.Notices.Queries;

namespace NoticeBoardService.API.Controllers;

[Route("api/[controller]")] 
public class NoticesController : BaseController // <--- USING BASECONTROLLER!
{
    private readonly IMediator _mediator;
    public NoticesController(IMediator mediator) => _mediator = mediator;

    [HttpPost]
    [Authorize(Roles = "Admin")] // Only admins can post notices!
    public async Task<IActionResult> CreateNotice([FromBody] CreateNoticeCommand command)
    {
        command.CreatedByUserId = GetUserId(); // <--- MAGIC FROM BASECONTROLLER
        var id = await _mediator.Send(command);
        return CreatedAtAction(nameof(CreateNotice), new { id }, new { Id = id });
    }

    [HttpGet]
    public async Task<IActionResult> GetNotices([FromQuery] Guid societyId)
    {
        var query = new GetNoticesQuery { SocietyId = societyId };
        var result = await _mediator.Send(query);
        return Ok(result);
    }
}