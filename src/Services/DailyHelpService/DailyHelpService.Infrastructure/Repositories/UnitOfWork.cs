using DailyHelpService.Domain.Interfaces;
using DailyHelpService.Infrastructure.Data;

namespace DailyHelpService.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly DailyHelpDbContext _context;
    public IHelpTypeRepository HelpTypes { get; }
    public IDailyHelpStaffRepository Staff { get; }
    public IDailyHelpAssignmentRepository Assignments { get; }

    public UnitOfWork(DailyHelpDbContext context, IHelpTypeRepository helpTypeRepo, IDailyHelpStaffRepository staffRepo, IDailyHelpAssignmentRepository assignmentRepo)
    {
        _context = context;
        HelpTypes = helpTypeRepo;
        Staff = staffRepo;
        Assignments = assignmentRepo;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) => await _context.SaveChangesAsync(cancellationToken);
    public void Dispose() { _context.Dispose(); GC.SuppressFinalize(this); }
}