using EmergencyService.Domain.Entities;
using EmergencyService.Domain.Enums;
using EmergencyService.Domain.Interfaces;
using EmergencyService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace EmergencyService.Infrastructure.Repositories;

public class EmergencyAlertRepository : IEmergencyAlertRepository
{
    private readonly EmergencyDbContext _context;
    public EmergencyAlertRepository(EmergencyDbContext context) => _context = context;

    public async Task<IReadOnlyList<EmergencyAlert>> GetActiveAlertsBySocietyAsync(Guid societyId, CancellationToken cancellationToken = default)
        => await _context.Alerts
            .Where(a => a.SocietyId == societyId && a.Status == AlertStatus.Active)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<EmergencyAlert>> GetByUserAsync(Guid societyId, Guid userId, CancellationToken cancellationToken = default)
        => await _context.Alerts
            .Where(a => a.SocietyId == societyId && a.TriggeredById == userId)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<EmergencyAlert?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.Alerts.FirstOrDefaultAsync(a => a.Id == id, cancellationToken);

    public void Add(EmergencyAlert alert) => _context.Alerts.Add(alert);
    public void Update(EmergencyAlert alert) => _context.Alerts.Update(alert);
}