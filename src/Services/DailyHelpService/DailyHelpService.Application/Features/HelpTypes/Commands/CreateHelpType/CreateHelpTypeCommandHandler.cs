using DailyHelpService.Domain.Interfaces;
using MediatR;

namespace DailyHelpService.Application.Features.HelpTypes.Commands.CreateHelpType;

public class CreateHelpTypeCommandHandler : IRequestHandler<CreateHelpTypeCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateHelpTypeCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Guid> Handle(CreateHelpTypeCommand request, CancellationToken cancellationToken)
    {
        var helpType = Domain.Entities.HelpType.Create(request.SocietyId, request.Name);
        _unitOfWork.HelpTypes.Add(helpType);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return helpType.Id;
    }
}