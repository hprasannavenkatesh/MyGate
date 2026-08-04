namespace DailyHelpService.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IHelpTypeRepository HelpTypes { get; }
    IDailyHelpStaffRepository Staff { get; }
    IDailyHelpAssignmentRepository Assignments { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}