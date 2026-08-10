using VehicleService.Domain.Entities;
using VehicleService.Domain.Enums;
using VehicleService.Domain.Interfaces;
using VehicleService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace VehicleService.Infrastructure.Repositories;

public class VehicleRepository : IVehicleRepository
{
    private readonly VehicleDbContext _context;
    public VehicleRepository(VehicleDbContext context) => _context = context;

    public async Task<IReadOnlyList<Vehicle>> GetByOwnerAsync(Guid societyId, Guid ownerId, CancellationToken cancellationToken = default)
        => await _context.Vehicles
            .Include(v => v.ParkingSlot)
            .Where(v => v.SocietyId == societyId && v.OwnerId == ownerId)
            .ToListAsync(cancellationToken);

    public async Task<Vehicle?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.Vehicles.Include(v => v.ParkingSlot).FirstOrDefaultAsync(v => v.Id == id, cancellationToken);

    public async Task<bool> IsVehicleNumberTakenAsync(Guid societyId, string vehicleNumber, CancellationToken cancellationToken = default)
        => await _context.Vehicles.AnyAsync(v => v.SocietyId == societyId && v.VehicleNumber == vehicleNumber.Trim().ToUpper(), cancellationToken);

    public void Add(Vehicle vehicle) => _context.Vehicles.Add(vehicle);
    public void Update(Vehicle vehicle) => _context.Vehicles.Update(vehicle);

    public async Task<int> CountActiveVehiclesByTypeAsync(Guid societyId, Guid flatId, VehicleType type, CancellationToken cancellationToken = default)
{
    return await _context.Vehicles
        .CountAsync(v => v.SocietyId == societyId && 
                         v.FlatId == flatId && 
                         v.VehicleType == type &&
                         v.Category == VehicleCategory.Resident, 
                         cancellationToken);
}
}