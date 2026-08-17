using EmergencyService.Domain.Entities;
using EmergencyService.Domain.Enums;

namespace EmergencyService.Domain.Interfaces;

public interface IEmergencyAlertRepository
{
    Task<IReadOnlyList<EmergencyAlert>> GetActiveAlertsBySocietyAsync(Guid societyId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<EmergencyAlert>> GetByUserAsync(Guid societyId, Guid userId, CancellationToken cancellationToken = default);
    Task<EmergencyAlert?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    void Add(EmergencyAlert alert);
    void Update(EmergencyAlert alert);
}