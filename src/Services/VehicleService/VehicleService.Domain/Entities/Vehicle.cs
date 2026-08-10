using VehicleService.Domain.Enums;

namespace VehicleService.Domain.Entities;

public class Vehicle : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public Guid OwnerId { get; private set; } 
    public Guid FlatId { get; private set; }
    
    public VehicleType VehicleType { get; private set; }
    public VehicleCategory Category { get; private set; } // NEW: Resident or Guest
    
    public string VehicleNumber { get; private set; } = string.Empty;
    public string? MakeModel { get; private set; }
    
    // NEW: Time tracking for Guests
    public DateTimeOffset? CheckInTime { get; private set; }
    public DateTimeOffset? ExpectedCheckOutTime { get; private set; }
    
    public Guid? ParkingSlotId { get; private set; }
    public virtual ParkingSlot? ParkingSlot { get; private set; }

    private Vehicle() { }

    public static Vehicle CreateResidentVehicle(Guid societyId, Guid ownerId, Guid flatId, string vehicleNumber, VehicleType vehicleType, string? makeModel)
    {
        if (string.IsNullOrWhiteSpace(vehicleNumber)) throw new ArgumentException("Vehicle number is required.");
        if (vehicleType == VehicleType.Visitor) throw new ArgumentException("Residents cannot register as Visitor type.");

        return new Vehicle
        {
            SocietyId = societyId,
            OwnerId = ownerId,
            FlatId = flatId,
            VehicleNumber = vehicleNumber.Trim().ToUpper(),
            VehicleType = vehicleType,
            Category = VehicleCategory.Resident,
            MakeModel = makeModel?.Trim()
        };
    }

    // NEW: Factory method for Guests
    public static Vehicle CreateGuestVehicle(Guid societyId, Guid flatId, string vehicleNumber, VehicleType vehicleType, string? makeModel, DateTimeOffset expectedCheckout)
    {
        if (string.IsNullOrWhiteSpace(vehicleNumber)) throw new ArgumentException("Vehicle number is required.");

        return new Vehicle
        {
            SocietyId = societyId,
            OwnerId = Guid.Empty, // Guest doesn't have an app account
            FlatId = flatId,
            VehicleNumber = vehicleNumber.Trim().ToUpper(),
            VehicleType = vehicleType,
            Category = VehicleCategory.Guest,
            MakeModel = makeModel?.Trim(),
            CheckInTime = DateTimeOffset.UtcNow,
            ExpectedCheckOutTime = expectedCheckout
        };
    }

    public void AssignSlot(Guid slotId)
    {
        ParkingSlotId = slotId;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void RemoveSlot()
    {
        ParkingSlotId = null;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}