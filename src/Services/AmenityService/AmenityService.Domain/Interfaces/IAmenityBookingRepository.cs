using AmenityService.Domain.Entities;
using AmenityService.Domain.Enums;

namespace AmenityService.Domain.Interfaces;

public interface IAmenityBookingRepository
{
    Task<AmenityBooking?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AmenityBooking>> GetByAmenityAndDateAsync(
        Guid amenityId, 
        DateOnly date, 
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AmenityBooking>> GetByAmenityAndDateRangeAsync(
        Guid amenityId, 
        DateOnly startDate, 
        DateOnly endDate, 
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AmenityBooking>> GetByUserAndSocietyAsync(
        Guid userId, 
        Guid societyId, 
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AmenityBooking>> GetByUserAndDateAsync(
        Guid userId, 
        DateOnly date, 
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AmenityBooking>> GetBySocietyAndDateAsync(
        Guid societyId, 
        DateOnly date, 
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AmenityBooking>> GetPendingBySocietyAsync(
        Guid societyId, 
        CancellationToken cancellationToken = default);
    Task<int> CountUserBookingsForDateAsync(
        Guid userId, 
        Guid amenityId, 
        DateOnly date, 
        CancellationToken cancellationToken = default);
    Task<bool> HasOverlappingBookingAsync(
        Guid amenityId, 
        DateOnly date, 
        TimeOnly startTime, 
        TimeOnly endTime, 
        CancellationToken cancellationToken = default);
    void Add(AmenityBooking booking);
    void Update(AmenityBooking booking);
}