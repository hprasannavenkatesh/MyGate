using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface IFlatRepository
{
    Task<Block> AddBlockAsync(Block block);
    Task<Flat> AddFlatAsync(Flat flat);
}