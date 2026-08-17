using EmergencyService.Domain.Interfaces;
using EmergencyService.Infrastructure.Data;

namespace EmergencyService.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly EmergencyDbContext _context;
    public IEmergencyAlertRepository Alerts { get; }

    public UnitOfWork(EmergencyDbContext context, IEmergencyAlertRepository alertRepo)
    {
        _context = context;
        Alerts = alertRepo;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) 
        => await _context.SaveChangesAsync(cancellationToken);

    public void Dispose() 
    { 
        _context.Dispose(); 
        GC.SuppressFinalize(this); 
    }
}