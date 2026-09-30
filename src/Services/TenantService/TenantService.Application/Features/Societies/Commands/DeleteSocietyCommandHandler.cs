using TenantService.Domain.Interfaces;
using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public class DeleteSocietyCommandHandler : IRequestHandler<DeleteSocietyCommand, Unit>
{
     private readonly ISocietyRepository _societyRepository;

    public DeleteSocietyCommandHandler(ISocietyRepository societyRepository)
    {
        _societyRepository = societyRepository;
    }

public async Task<Unit> Handle(DeleteSocietyCommand request, CancellationToken cancellationToken)
{
    var society = await _societyRepository.GetByIdAsync(request.SocietyId, cancellationToken)
        ?? throw new KeyNotFoundException($"Society with ID {request.SocietyId} not found.");

    _societyRepository.Delete(society);
    await _societyRepository.SaveChangesAsync(cancellationToken); // This now works!

    return Unit.Value;
}
}