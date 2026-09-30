using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface IFlatRepository
{
    Task<Block> AddBlockAsync(Block block);
    Task<Flat> AddFlatAsync(Flat flat);

      // NEW: Read operations (Crucial for React Admin Portal)
    Task<IReadOnlyList<Block>> GetBlocksBySocietyAsync(Guid societyId, CancellationToken ct = default);
    Task<IReadOnlyList<Flat>> GetFlatsByBlockAsync(Guid blockId, CancellationToken ct = default);
    
    // NEW: Delete operations
    void RemoveFlat(Flat flat);
    void RemoveBlock(Block block);
}