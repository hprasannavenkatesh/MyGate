using DailyHelpService.Domain.Entities;
using DailyHelpService.Domain.Interfaces;
using DailyHelpService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DailyHelpService.Infrastructure.Repositories;

public class DailyHelpAssignmentRepository : IDailyHelpAssignmentRepository
{
    private readonly DailyHelpDbContext _context;
    public DailyHelpAssignmentRepository(DailyHelpDbContext context) => _context = context;

    public async Task<IReadOnlyList<DailyHelpAssignment>> GetByFlatIdAsync(Guid flatId, CancellationToken cancellationToken = default)
        => await _context.Assignments
            .Include(a => a.Staff)
            .ThenInclude(s => s.HelpType) // Crucial for the DTO mapping!
            .Where(a => a.FlatId == flatId)
            .ToListAsync(cancellationToken);

    public async Task<DailyHelpAssignment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.Assignments.Include(a => a.Staff).FirstOrDefaultAsync(a => a.Id == id, cancellationToken);

    public void Add(DailyHelpAssignment assignment) => _context.Assignments.Add(assignment);
    public void Update(DailyHelpAssignment assignment) => _context.Assignments.Update(assignment);
    public void Remove(DailyHelpAssignment assignment) => _context.Assignments.Remove(assignment);
}