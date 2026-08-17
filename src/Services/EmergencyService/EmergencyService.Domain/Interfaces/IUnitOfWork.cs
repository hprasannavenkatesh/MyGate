namespace EmergencyService.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IEmergencyAlertRepository Alerts { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}