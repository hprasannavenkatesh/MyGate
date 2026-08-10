using VehicleService.Domain.Entities;
using VehicleService.Domain.Enums;
using VehicleService.Domain.Interfaces;
using VehicleService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace VehicleService.Infrastructure.Repositories;

public class ParkingSlotRepository : IParkingSlotRepository
{
    private readonly VehicleDbContext _context;
    public ParkingSlotRepository(VehicleDbContext context) => _context = context;

    public async Task<ParkingSlot?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.ParkingSlots.Include(s => s.ParkedVehicle).FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

    public async Task<IReadOnlyList<ParkingSlot>> GetAvailableSlotsAsync(Guid societyId, VehicleType type, CancellationToken cancellationToken = default)
        => await _context.ParkingSlots
            .Where(s => s.SocietyId == societyId && s.SlotType == type && !s.IsOccupied)
            .OrderBy(s => s.SlotNumber)
            .ToListAsync(cancellationToken);

    public async Task<bool> IsSlotNumberTakenAsync(Guid societyId, string slotNumber, CancellationToken cancellationToken = default)
        => await _context.ParkingSlots.AnyAsync(s => s.SocietyId == societyId && s.SlotNumber == slotNumber.Trim(), cancellationToken);

    public async Task<IReadOnlyList<ParkingSlot>> GetBySocietyAsync(Guid societyId, VehicleType? type = null, bool? isOccupied = null, CancellationToken cancellationToken = default)
    {
        var query = _context.ParkingSlots.Where(s => s.SocietyId == societyId);
        
        if (type.HasValue) query = query.Where(s => s.SlotType == type.Value);
        if (isOccupied.HasValue) query = query.Where(s => s.IsOccupied == isOccupied.Value);
        
        return await query.OrderBy(s => s.SlotType).ThenBy(s => s.SlotNumber).ToListAsync(cancellationToken);
    }

    public void Add(ParkingSlot slot) => _context.ParkingSlots.Add(slot);
    public void Update(ParkingSlot slot) => _context.ParkingSlots.Update(slot);
}