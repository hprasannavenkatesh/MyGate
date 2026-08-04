namespace AmenityService.Domain.Entities;

public class Amenity : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public string? Location { get; private set; }
    public bool IsActive { get; private set; } = true;
    public bool IsBookable { get; private set; } = true;
    
    // Slot Configuration
    public int SlotDurationMinutes { get; private set; } = 60;
    public int MaxBookingsPerDayPerUser { get; private set; } = 1;
    public int AdvanceBookingDaysAllowed { get; private set; } = 7;
    
    // Operating Hours
    public TimeOnly OperatingHoursStart { get; private set; } = new(6, 0);
    public TimeOnly OperatingHoursEnd { get; private set; } = new(22, 0);
    
    // Navigation
    public virtual ICollection<AmenityBooking> Bookings { get; private set; } = new List<AmenityBooking>();

    private Amenity() { } // EF Core

    public static Amenity Create(
        Guid societyId,
        string name,
        string? description,
        string? location,
        bool isBookable,
        int slotDurationMinutes,
        int maxBookingsPerDayPerUser,
        int advanceBookingDaysAllowed,
        TimeOnly operatingHoursStart,
        TimeOnly operatingHoursEnd)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Amenity name is required.", nameof(name));

        if (slotDurationMinutes < 15 || slotDurationMinutes > 480)
            throw new ArgumentException("Slot duration must be between 15 and 480 minutes.", nameof(slotDurationMinutes));

        if (maxBookingsPerDayPerUser < 1)
            throw new ArgumentException("Max bookings per day must be at least 1.", nameof(maxBookingsPerDayPerUser));

        if (advanceBookingDaysAllowed < 0 || advanceBookingDaysAllowed > 30)
            throw new ArgumentException("Advance booking days must be between 0 and 30.", nameof(advanceBookingDaysAllowed));

        if (operatingHoursStart >= operatingHoursEnd)
            throw new ArgumentException("Operating hours start must be before end.", nameof(operatingHoursStart));

        return new Amenity
        {
            SocietyId = societyId,
            Name = name.Trim(),
            Description = description?.Trim(),
            Location = location?.Trim(),
            IsBookable = isBookable,
            SlotDurationMinutes = slotDurationMinutes,
            MaxBookingsPerDayPerUser = maxBookingsPerDayPerUser,
            AdvanceBookingDaysAllowed = advanceBookingDaysAllowed,
            OperatingHoursStart = operatingHoursStart,
            OperatingHoursEnd = operatingHoursEnd
        };
    }

    public void Update(
        string name,
        string? description,
        string? location,
        bool isBookable,
        int slotDurationMinutes,
        int maxBookingsPerDayPerUser,
        int advanceBookingDaysAllowed,
        TimeOnly operatingHoursStart,
        TimeOnly operatingHoursEnd)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Amenity name is required.", nameof(name));

        if (slotDurationMinutes < 15 || slotDurationMinutes > 480)
            throw new ArgumentException("Slot duration must be between 15 and 480 minutes.", nameof(slotDurationMinutes));

        if (operatingHoursStart >= operatingHoursEnd)
            throw new ArgumentException("Operating hours start must be before end.", nameof(operatingHoursStart));

        Name = name.Trim();
        Description = description?.Trim();
        Location = location?.Trim();
        IsBookable = isBookable;
        SlotDurationMinutes = slotDurationMinutes;
        MaxBookingsPerDayPerUser = Math.Max(1, maxBookingsPerDayPerUser);
        AdvanceBookingDaysAllowed = Math.Clamp(advanceBookingDaysAllowed, 0, 30);
        OperatingHoursStart = operatingHoursStart;
        OperatingHoursEnd = operatingHoursEnd;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Deactivate()
    {
        IsActive = false;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Activate()
    {
        IsActive = true;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}