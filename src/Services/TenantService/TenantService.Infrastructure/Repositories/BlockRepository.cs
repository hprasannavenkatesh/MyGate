using Microsoft.EntityFrameworkCore;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;
using TenantService.Infrastructure.Persistence;

namespace TenantService.Infrastructure.Repositories;

public class BlockRepository : IBlockRepository
{
    private readonly TenantDbContext _context;
    public BlockRepository(TenantDbContext context) => _context = context;

    public async Task<Block?> GetByIdAsync(Guid id, CancellationToken ct = default) 
        => await _context.Blocks.FindAsync(id, ct);

    public async Task<IReadOnlyList<Block>> GetBySocietyAsync(Guid societyId, CancellationToken ct = default) 
        => await _context.Blocks.Where(b => b.SocietyId == societyId).OrderBy(b => b.Name).ToListAsync(ct);

    public void Add(Block block) => _context.Blocks.Add(block);
    public void Update(Block block) => _context.Blocks.Update(block);
    public void Remove(Block block) => _context.Blocks.Remove(block);
}