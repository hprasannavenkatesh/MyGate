using VisitorService.Domain.Entities;
using VisitorService.Domain.Interfaces;
using VisitorService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace VisitorService.Infrastructure.Repositories;

public class VisitorLogRepository : IVisitorLogRepository
{
    private readonly VisitorDbContext _context;

    public VisitorLogRepository(VisitorDbContext context)
    {
        _context = context;
    }

    public async Task<VisitorLog> AddAsync(VisitorLog log)
    {
        await _context.VisitorLogs.AddAsync(log);
        await _context.SaveChangesAsync();
        return log;
    }

    public async Task<VisitorLog?> GetByIdAsync(Guid id)
    {
        return await _context.VisitorLogs.FindAsync(id);
    }

        public async Task UpdateAsync(VisitorLog log)
    {
        _context.VisitorLogs.Update(log);
        await _context.SaveChangesAsync();
    }
}