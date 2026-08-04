namespace AmenityService.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IAmenityRepository Amenities { get; }
    IAmenityBookingRepository AmenityBookings { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}