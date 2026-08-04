using MediatR;
using NoticeBoardService.Domain.Entities;

namespace NoticeBoardService.Application.Features.Notices.Commands;

public class CreateNoticeCommand : IRequest<Guid>
{
    public Guid SocietyId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Category { get; set; } = 0;
    public bool IsPinned { get; set; } = false;
    public Guid CreatedByUserId { get; set; }
}