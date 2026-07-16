using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;
using TenantService.Infrastructure.Persistence;

namespace TenantService.Infrastructure.Repositories;

public class FlatRepository : IFlatRepository
{
    private readonly TenantDbContext _context;
    public FlatRepository(TenantDbContext context) => _context = context;

    public async Task<Block> AddBlockAsync(Block block)
    {
        await _context.Blocks.AddAsync(block);
        await _context.SaveChangesAsync();
        return block;
    }

    public async Task<Flat> AddFlatAsync(Flat flat)
    {
        await _context.Flats.AddAsync(flat);
        await _context.SaveChangesAsync();
        return flat;
    }
}