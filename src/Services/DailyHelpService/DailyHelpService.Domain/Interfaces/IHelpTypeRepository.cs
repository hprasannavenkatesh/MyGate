using DailyHelpService.Domain.Entities;

namespace DailyHelpService.Domain.Interfaces;

public interface IHelpTypeRepository
{
    Task<HelpType?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<HelpType>> GetBySocietyAsync(Guid societyId, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    void Add(HelpType helpType);
    void Update(HelpType helpType);
}