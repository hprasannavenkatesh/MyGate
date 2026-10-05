using TenantService.Domain.Interfaces;
using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public class DeleteSocietyCommandHandler : IRequestHandler<DeleteSocietyCommand, Unit>
{
    private readonly ISocietyRepository _societyRepo;
    private readonly IFlatRepository _flatRepo;
    private readonly ISocietyMemberRepository _memberRepo;

    public DeleteSocietyCommandHandler(
        ISocietyRepository societyRepo,
        IFlatRepository flatRepo,
        ISocietyMemberRepository memberRepo)
    {
        _societyRepo = societyRepo;
        _flatRepo = flatRepo;
        _memberRepo = memberRepo;
    }

    public async Task<Unit> Handle(DeleteSocietyCommand request, CancellationToken cancellationToken)
    {
        var society = await _societyRepo.GetByIdAsync(request.SocietyId, cancellationToken)
            ?? throw new KeyNotFoundException($"Society with ID {request.SocietyId} not found.");

        // 1. Delete all members in this society
        var members = await _memberRepo.GetBySocietyIdAsync(request.SocietyId, cancellationToken);
        foreach (var member in members)
            _memberRepo.Remove(member);
        await _memberRepo.SaveChangesAsync(cancellationToken);

        // 2. Delete all flats and blocks in this society
        var blocks = await _flatRepo.GetBlocksBySocietyAsync(request.SocietyId, cancellationToken);
        foreach (var block in blocks)
        {
            var flats = await _flatRepo.GetFlatsByBlockAsync(block.Id, cancellationToken);
            foreach (var flat in flats)
                _flatRepo.RemoveFlat(flat);
            _flatRepo.RemoveBlock(block);
        }
        await _societyRepo.SaveChangesAsync(cancellationToken);

        // 3. Delete the society itself
        _societyRepo.Delete(society);
        await _societyRepo.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}

/*using TenantService.Domain.Interfaces;
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
}*/