namespace VehicleService.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IParkingSlotRepository ParkingSlots { get; }
    IVehicleRepository Vehicles { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}