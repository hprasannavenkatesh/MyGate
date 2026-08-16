using DirectoryService.Application.DTOs;
using DirectoryService.Domain.Interfaces;
using MediatR;

namespace DirectoryService.Application.Features.Directory.Queries.GetDirectory;

public class GetDirectoryQueryHandler : IRequestHandler<GetDirectoryQuery, IReadOnlyList<DirectoryEntryDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetDirectoryQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<IReadOnlyList<DirectoryEntryDto>> Handle(GetDirectoryQuery request, CancellationToken cancellationToken)
    {
        var entries = await _unitOfWork.Directory.GetBySocietyAsync(request.SocietyId, request.Category, request.Search, cancellationToken);
        return entries.Select(e => new DirectoryEntryDto(e.Id, e.Category, e.Name, e.ContactNumber, e.Email, e.Address, e.Notes)).ToList();
    }
}