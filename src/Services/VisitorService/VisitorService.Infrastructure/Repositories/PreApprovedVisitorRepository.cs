using VisitorService.Domain.Entities;
using VisitorService.Domain.Interfaces;
using VisitorService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace VisitorService.Infrastructure.Repositories;

public class PreApprovedVisitorRepository : IPreApprovedVisitorRepository
{
    private readonly VisitorDbContext _context;

    public PreApprovedVisitorRepository(VisitorDbContext context)
    {
        _context = context;
    }

    public async Task<PreApprovedVisitor> AddAsync(PreApprovedVisitor visitor)
    {
        await _context.PreApprovedVisitors.AddAsync(visitor);
        await _context.SaveChangesAsync();
        return visitor;
    }

    public async Task<PreApprovedVisitor?> GetByIdAsync(Guid id)
    {
        return await _context.PreApprovedVisitors.FindAsync(id);
    }

        public async Task<List<PreApprovedVisitor>> GetByInviterIdAsync(Guid inviterId)
    {
        return await _context.PreApprovedVisitors
            .Where(v => v.InvitedByUserId == inviterId)
            .OrderByDescending(v => v.ExpectedDate)
            .ToListAsync();
    }
    // ← ADD THIS METHOD
    public async Task UpdateAsync(PreApprovedVisitor visitor)
    {
        _context.PreApprovedVisitors.Update(visitor);
        await _context.SaveChangesAsync();
    }

    // NEW: Get all visitors for a society (Admin view)
    public async Task<List<PreApprovedVisitor>> GetBySocietyIdAsync(Guid societyId)
    {
        return await _context.PreApprovedVisitors
            .Where(v => v.SocietyId == societyId)
            .OrderByDescending(v => v.ExpectedDate)
            .ToListAsync();
    }
}