using DailyHelpService.Domain.Entities;

namespace DailyHelpService.Domain.Interfaces;

public interface IDailyHelpAssignmentRepository
{
    Task<IReadOnlyList<DailyHelpAssignment>> GetByFlatIdAsync(Guid flatId, CancellationToken cancellationToken = default);
    Task<DailyHelpAssignment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    void Add(DailyHelpAssignment assignment);
    void Update(DailyHelpAssignment assignment);
    void Remove(DailyHelpAssignment assignment);
}