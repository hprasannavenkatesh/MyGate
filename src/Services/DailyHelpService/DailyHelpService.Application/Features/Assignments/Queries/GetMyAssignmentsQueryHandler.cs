using DailyHelpService.Application.DTOs;
using DailyHelpService.Domain.Interfaces;
using MediatR;

namespace DailyHelpService.Application.Features.Assignments.Queries.GetMyAssignments;

public class GetMyAssignmentsQueryHandler : IRequestHandler<GetMyAssignmentsQuery, IReadOnlyList<DailyHelpAssignmentDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetMyAssignmentsQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<DailyHelpAssignmentDto>> Handle(GetMyAssignmentsQuery request, CancellationToken cancellationToken)
    {
        var assignments = await _unitOfWork.Assignments.GetByFlatIdAsync(request.FlatId, cancellationToken);
        return assignments.Select(a => new DailyHelpAssignmentDto(
            a.Id,
            a.StaffId,
            a.Staff.Name,
            a.Staff.MobileNumber,
            a.Staff.HelpType.Name, // Traversing Staff -> HelpType
            a.FlatId,
            a.WorkingDays,
            a.InTime?.ToString("HH:mm"),
            a.OutTime?.ToString("HH:mm"),
            a.IsActive
        )).ToList();
    }
}