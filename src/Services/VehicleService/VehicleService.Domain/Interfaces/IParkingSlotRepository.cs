using VehicleService.Domain.Entities;
using VehicleService.Domain.Enums;

namespace VehicleService.Domain.Interfaces;

public interface IParkingSlotRepository
{
    Task<ParkingSlot?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ParkingSlot>> GetAvailableSlotsAsync(Guid societyId, VehicleType type, CancellationToken cancellationToken = default);
    Task<bool> IsSlotNumberTakenAsync(Guid societyId, string slotNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ParkingSlot>> GetBySocietyAsync(Guid societyId, VehicleType? type = null, bool? isOccupied = null, CancellationToken cancellationToken = default);
    
    void Add(ParkingSlot slot);
    void Update(ParkingSlot slot);
}