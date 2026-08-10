using VehicleService.Domain.Entities;
using VehicleService.Domain.Enums;

namespace VehicleService.Domain.Interfaces;

public interface IVehicleRepository
{
    Task<IReadOnlyList<Vehicle>> GetByOwnerAsync(Guid societyId, Guid ownerId, CancellationToken cancellationToken = default);
    Task<Vehicle?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> IsVehicleNumberTakenAsync(Guid societyId, string vehicleNumber, CancellationToken cancellationToken = default);

    Task<int> CountActiveVehiclesByTypeAsync(Guid societyId, Guid flatId, VehicleType type, CancellationToken cancellationToken = default);

    void Add(Vehicle vehicle);
    void Update(Vehicle vehicle);
}