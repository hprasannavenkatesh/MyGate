using DailyHelpService.Domain.Interfaces;
using MediatR;

namespace DailyHelpService.Application.Features.Assignments.Commands.AssignStaff;

public class AssignStaffCommandHandler : IRequestHandler<AssignStaffCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public AssignStaffCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Guid> Handle(AssignStaffCommand request, CancellationToken cancellationToken)
    {
        var staff = await _unitOfWork.Staff.GetByIdAsync(request.StaffId, cancellationToken)
            ?? throw new KeyNotFoundException("Staff not found.");

        if (staff.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("Staff does not belong to this society.");

        TimeOnly? inTime = string.IsNullOrWhiteSpace(request.InTime) ? null : TimeOnly.Parse(request.InTime);
        TimeOnly? outTime = string.IsNullOrWhiteSpace(request.OutTime) ? null : TimeOnly.Parse(request.OutTime);

        var assignment = Domain.Entities.DailyHelpAssignment.Create(
            request.StaffId, request.FlatId, request.SocietyId, request.WorkingDays, inTime, outTime);

        _unitOfWork.Assignments.Add(assignment);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return assignment.Id;
    }
}