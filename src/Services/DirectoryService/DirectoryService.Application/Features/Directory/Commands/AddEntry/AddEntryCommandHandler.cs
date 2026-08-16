using DirectoryService.Domain.Interfaces;
using MediatR;

namespace DirectoryService.Application.Features.Directory.Commands.AddEntry;

public class AddEntryCommandHandler : IRequestHandler<AddEntryCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public AddEntryCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Guid> Handle(AddEntryCommand request, CancellationToken cancellationToken)
    {
        var entry = Domain.Entities.DirectoryEntry.Create(
            request.SocietyId, request.Category, request.Name, request.ContactNumber, request.Email, request.Address, request.Notes);

        _unitOfWork.Directory.Add(entry);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return entry.Id;
    }
}