using VehicleService.Domain.Interfaces;
using VehicleService.Infrastructure.Data;

namespace VehicleService.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly VehicleDbContext _context;
    public IParkingSlotRepository ParkingSlots { get; }
    public IVehicleRepository Vehicles { get; }

    public UnitOfWork(VehicleDbContext context, IParkingSlotRepository slotRepo, IVehicleRepository vehicleRepo)
    {
        _context = context;
        ParkingSlots = slotRepo;
        Vehicles = vehicleRepo;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) => await _context.SaveChangesAsync(cancellationToken);
    public void Dispose() { _context.Dispose(); GC.SuppressFinalize(this); }
}