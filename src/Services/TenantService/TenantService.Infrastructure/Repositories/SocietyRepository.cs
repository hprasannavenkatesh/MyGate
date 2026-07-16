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
}