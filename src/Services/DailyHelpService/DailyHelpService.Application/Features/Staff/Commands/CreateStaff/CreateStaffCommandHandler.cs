using DailyHelpService.Domain.Interfaces;
using MediatR;

namespace DailyHelpService.Application.Features.Staff.Commands.CreateStaff;

public class CreateStaffCommandHandler : IRequestHandler<CreateStaffCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateStaffCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Guid> Handle(CreateStaffCommand request, CancellationToken cancellationToken)
    {
        var helpType = await _unitOfWork.HelpTypes.GetByIdAsync(request.HelpTypeId, cancellationToken)
            ?? throw new KeyNotFoundException("Help Type not found.");

        if (helpType.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("Help Type does not belong to this society.");

        var staff = Domain.Entities.DailyHelpStaff.Create(
            request.SocietyId, request.Name, request.MobileNumber, request.HelpTypeId, request.AgencyName);

        _unitOfWork.Staff.Add(staff);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return staff.Id;
    }
}