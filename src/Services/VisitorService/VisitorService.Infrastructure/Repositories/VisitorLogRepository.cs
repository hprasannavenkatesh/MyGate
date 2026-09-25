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

     // NEW: Find the active log for a pre-approval
    public async Task<VisitorLog?> GetActiveByPreApprovalIdAsync(Guid preApprovalId)
    {
        return await _context.VisitorLogs
            .Where(l => l.PreApprovalId == preApprovalId &&  l.Status == VisitorStatus.Inside)
            .OrderByDescending(l => l.EntryTime)
            .FirstOrDefaultAsync();
    }
}