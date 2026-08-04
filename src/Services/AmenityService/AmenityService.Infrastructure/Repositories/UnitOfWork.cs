using AmenityService.Domain.Interfaces;
using AmenityService.Infrastructure.Data;

namespace AmenityService.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AmenityDbContext _context;

    public IAmenityRepository Amenities { get; }
    public IAmenityBookingRepository AmenityBookings { get; }

    public UnitOfWork(
        AmenityDbContext context,
        IAmenityRepository amenityRepository,
        IAmenityBookingRepository amenityBookingRepository)
    {
        _context = context;
        Amenities = amenityRepository;
        AmenityBookings = amenityBookingRepository;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public void Dispose()
    {
        _context.Dispose();
        GC.SuppressFinalize(this);
    }
}