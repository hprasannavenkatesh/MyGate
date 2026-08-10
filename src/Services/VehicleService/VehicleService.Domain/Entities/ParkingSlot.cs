using VehicleService.Domain.Enums;

namespace VehicleService.Domain.Entities;

public class ParkingSlot : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public string SlotNumber { get; private set; } = string.Empty;
    public VehicleType SlotType { get; private set; }

 // NEW: Location Mapping
    public Guid? BlockId { get; private set; }
    public Guid? FlatId { get; private set; } // If populated, this slot is strictly allotted to this flat
    
    public string? BlockName { get; private set; }
    public bool IsOccupied { get; private set; } = false;
    
    public virtual Vehicle? ParkedVehicle { get; private set; }

    private ParkingSlot() { }

   public static ParkingSlot Create(Guid societyId, string slotNumber, VehicleType slotType, Guid? blockId, Guid? flatId)
    {
        if (string.IsNullOrWhiteSpace(slotNumber)) throw new ArgumentException("Slot number is required.");

        return new ParkingSlot
        {
            SocietyId = societyId,
            SlotNumber = slotNumber.Trim(),
            SlotType = slotType,
            BlockId = blockId,
            FlatId = flatId
        };
    }

    public void MarkOccupied() { IsOccupied = true; UpdatedAt = DateTimeOffset.UtcNow; }
    public void MarkVacant() { IsOccupied = false; UpdatedAt = DateTimeOffset.UtcNow; }
}