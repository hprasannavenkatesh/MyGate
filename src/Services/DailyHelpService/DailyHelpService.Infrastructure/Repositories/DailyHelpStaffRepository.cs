using DailyHelpService.Domain.Entities;
using DailyHelpService.Domain.Interfaces;
using DailyHelpService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DailyHelpService.Infrastructure.Repositories;

public class DailyHelpStaffRepository : IDailyHelpStaffRepository
{
    private readonly DailyHelpDbContext _context;
    public DailyHelpStaffRepository(DailyHelpDbContext context) => _context = context;

    public async Task<DailyHelpStaff?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.Staff.Include(s => s.HelpType).Include(s => s.Assignments).FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

    public async Task<IReadOnlyList<DailyHelpStaff>> GetBySocietyAsync(Guid societyId, Guid? helpTypeId = null, CancellationToken cancellationToken = default)
    {
        var query = _context.Staff.Include(s => s.HelpType).Where(s => s.SocietyId == societyId);
        if (helpTypeId.HasValue) query = query.Where(s => s.HelpTypeId == helpTypeId.Value);
        return await query.OrderBy(s => s.Name).ToListAsync(cancellationToken);
    }

    public void Add(DailyHelpStaff staff) => _context.Staff.Add(staff);
    public void Update(DailyHelpStaff staff) => _context.Staff.Update(staff);
}