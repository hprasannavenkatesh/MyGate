using Microsoft.EntityFrameworkCore;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;
using TenantService.Infrastructure.Persistence;

namespace TenantService.Infrastructure.Repositories;

public class SocietyRepository : ISocietyRepository
{
    private readonly TenantDbContext _context;
    public SocietyRepository(TenantDbContext context) => _context = context;

    public async Task<Society> AddAsync(Society society)
    {
        await _context.Societies.AddAsync(society);
        await _context.SaveChangesAsync();
        return society;
    }

      public async Task<Society?> GetByIdAsync(Guid id, CancellationToken ct = default) 
        => await _context.Societies.FindAsync(id, ct);

         public async Task<IReadOnlyList<Society>> GetAllAsync(CancellationToken ct = default) 
        => await _context.Societies.AsQueryable().OrderBy(s => s.Name).ToListAsync(ct);

       
    public void Add(Society society) => _context.Societies.Add(society);
    public void Update(Society society) => _context.Societies.Update(society);

    public void Delete(Society society) => _context.Societies.Remove(society);

    public async Task<int> SaveChangesAsync(CancellationToken ct = default) 
    => await _context.SaveChangesAsync(ct);
}