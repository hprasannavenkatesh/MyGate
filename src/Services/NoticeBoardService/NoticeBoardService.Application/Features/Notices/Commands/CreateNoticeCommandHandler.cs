using MediatR;
using NoticeBoardService.Domain.Entities;
using NoticeBoardService.Domain.Interfaces; 

namespace NoticeBoardService.Application.Features.Notices.Commands;

public class CreateNoticeCommandHandler : IRequestHandler<CreateNoticeCommand, Guid>
{
    private readonly INoticeRepository _repository;
    public CreateNoticeCommandHandler(INoticeRepository repository) => _repository = repository;

    public async Task<Guid> Handle(CreateNoticeCommand request, CancellationToken cancellationToken)
    {
        var notice = new Notice(
            request.SocietyId,
            request.Title,
            request.Description,
            (NoticeCategory)request.Category,
            request.IsPinned,
            request.CreatedByUserId
        );

        return (await _repository.AddAsync(notice)).Id;
    }
}