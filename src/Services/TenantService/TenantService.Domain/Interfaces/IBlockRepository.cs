using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface IBlockRepository
{
    Task<Block?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<Block>> GetBySocietyAsync(Guid societyId, CancellationToken ct = default);
    void Add(Block block);
    void Update(Block block);
    void Remove(Block block);
}