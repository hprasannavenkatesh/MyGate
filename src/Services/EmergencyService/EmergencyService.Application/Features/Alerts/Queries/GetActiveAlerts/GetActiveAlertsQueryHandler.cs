using EmergencyService.Application.DTOs;
using EmergencyService.Domain.Interfaces;
using MediatR;

namespace EmergencyService.Application.Features.Alerts.Queries.GetActiveAlerts;

public class GetActiveAlertsQueryHandler : IRequestHandler<GetActiveAlertsQuery, IReadOnlyList<EmergencyAlertDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetActiveAlertsQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<EmergencyAlertDto>> Handle(GetActiveAlertsQuery request, CancellationToken cancellationToken)
    {
        var alerts = await _unitOfWork.Alerts.GetActiveAlertsBySocietyAsync(request.SocietyId, cancellationToken);
        return alerts.Select(a => new EmergencyAlertDto(a.Id, a.Type, a.Description, a.Status, a.CreatedAt)).ToList();
    }
}