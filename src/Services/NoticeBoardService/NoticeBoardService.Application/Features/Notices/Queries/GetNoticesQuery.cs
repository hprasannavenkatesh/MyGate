using MediatR;
using NoticeBoardService.Domain.Entities;
using NoticeBoardService.Domain.Interfaces; 

namespace NoticeBoardService.Application.Features.Notices.Queries;

public class GetNoticesQuery : IRequest<List<Notice>>
{
    public Guid SocietyId { get; set; }
}

public class GetNoticesQueryHandler : IRequestHandler<GetNoticesQuery, List<Notice>>
{
    private readonly INoticeRepository _repository;
    public GetNoticesQueryHandler(INoticeRepository repository) => _repository = repository;

    public async Task<List<Notice>> Handle(GetNoticesQuery request, CancellationToken cancellationToken)
    {
        return (await _repository.GetBySocietyAsync(request.SocietyId)).ToList();
    }
}