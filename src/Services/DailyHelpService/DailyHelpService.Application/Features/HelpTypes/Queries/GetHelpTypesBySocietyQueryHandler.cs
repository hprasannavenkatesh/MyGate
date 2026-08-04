using DailyHelpService.Application.DTOs;
using DailyHelpService.Domain.Interfaces;
using MediatR;

namespace DailyHelpService.Application.Features.HelpTypes.Queries.GetHelpTypesBySociety;

public class GetHelpTypesBySocietyQueryHandler : IRequestHandler<GetHelpTypesBySocietyQuery, IReadOnlyList<HelpTypeDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetHelpTypesBySocietyQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<HelpTypeDto>> Handle(GetHelpTypesBySocietyQuery request, CancellationToken cancellationToken)
    {
        var types = await _unitOfWork.HelpTypes.GetBySocietyAsync(request.SocietyId, cancellationToken);
        return types.Select(t => new HelpTypeDto(t.Id, t.Name)).ToList();
    }
}