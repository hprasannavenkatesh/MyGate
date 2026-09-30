using Microsoft.EntityFrameworkCore;
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

      public async Task<Flat?> GetByIdAsync(Guid id, CancellationToken ct = default) 
        => await _context.Flats.FindAsync(id, ct);


    public async Task<IReadOnlyList<Flat>> GetByBlockAsync(Guid blockId, CancellationToken ct = default) 
        => await _context.Flats.Where(f => f.BlockId == blockId).OrderBy(f => f.FlatNumber).ToListAsync(ct);

    //public void Add(Flat flat) => _context.Flats.Add(flat);
    //public void Remove(Flat flat) => _context.Flats.Remove(flat);

        // NEW: Read operations
    public async Task<IReadOnlyList<Block>> GetBlocksBySocietyAsync(Guid societyId, CancellationToken ct = default)
        => await _context.Blocks.AsQueryable().Where(b => b.SocietyId == societyId).OrderBy(b => b.Name).ToListAsync(ct);

    public async Task<IReadOnlyList<Flat>> GetFlatsByBlockAsync(Guid blockId, CancellationToken ct = default)
        => await _context.Flats.AsQueryable().Where(f => f.BlockId == blockId).OrderBy(f => f.FlatNumber).ToListAsync(ct);

    // NEW: Delete operations
    public void RemoveFlat(Flat flat) => _context.Flats.Remove(flat);
    public void RemoveBlock(Block block) => _context.Blocks.Remove(block);
}