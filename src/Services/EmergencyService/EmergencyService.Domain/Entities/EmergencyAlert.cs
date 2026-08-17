using EmergencyService.Domain.Enums;

namespace EmergencyService.Domain.Entities;

public class EmergencyAlert : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public Guid TriggeredById { get; private set; }
    public Guid FlatId { get; private set; }
    public EmergencyType Type { get; private set; }
    public string? Description { get; private set; }
    public AlertStatus Status { get; private set; } = AlertStatus.Active;
    
    public Guid? ResolvedById { get; private set; }
    public DateTimeOffset? ResolvedAt { get; private set; }

    private EmergencyAlert() { }

    public static EmergencyAlert Create(Guid societyId, Guid triggeredById, Guid flatId, EmergencyType type, string? description)
    {
        return new EmergencyAlert
        {
            SocietyId = societyId,
            TriggeredById = triggeredById,
            FlatId = flatId,
            Type = type,
            Description = description?.Trim()
        };
    }

    public void Resolve(Guid resolvedById)
    {
        if (Status != AlertStatus.Active) throw new InvalidOperationException("Alert is already resolved.");
        Status = AlertStatus.Resolved;
        ResolvedById = resolvedById;
        ResolvedAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}