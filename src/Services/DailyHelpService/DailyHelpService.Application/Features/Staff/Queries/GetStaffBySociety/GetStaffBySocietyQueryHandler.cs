using DailyHelpService.Application.DTOs;
using DailyHelpService.Domain.Interfaces;
using MediatR;

namespace DailyHelpService.Application.Features.Staff.Queries.GetStaffBySociety;

public class GetStaffBySocietyQueryHandler : IRequestHandler<GetStaffBySocietyQuery, IReadOnlyList<DailyHelpStaffDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetStaffBySocietyQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<DailyHelpStaffDto>> Handle(GetStaffBySocietyQuery request, CancellationToken cancellationToken)
    {
        var staff = await _unitOfWork.Staff.GetBySocietyAsync(request.SocietyId, request.HelpTypeId, cancellationToken);
        return staff.Select(s => new DailyHelpStaffDto(
            s.Id, s.Name, s.MobileNumber, s.HelpTypeId, s.HelpType.Name, s.AgencyName, s.IsActive
        )).ToList();
    }
}