using DirectoryService.Domain.Interfaces;
using MediatR;

namespace DirectoryService.Application.Features.Directory.Commands.DeleteEntry;

public class DeleteEntryCommandHandler : IRequestHandler<DeleteEntryCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public DeleteEntryCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Unit> Handle(DeleteEntryCommand request, CancellationToken cancellationToken)
    {
        var entry = await _unitOfWork.Directory.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException("Directory entry not found.");

        if (entry.SocietyId != request.SocietyId) throw new UnauthorizedAccessException();

        _unitOfWork.Directory.Remove(entry);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Unit.Value;
    }
}