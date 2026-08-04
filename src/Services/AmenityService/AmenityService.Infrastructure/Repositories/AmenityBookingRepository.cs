using AmenityService.Domain.Entities;
using AmenityService.Domain.Enums;
using AmenityService.Domain.Interfaces;
using AmenityService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace AmenityService.Infrastructure.Repositories;

public class AmenityBookingRepository : IAmenityBookingRepository
{
    private readonly AmenityDbContext _context;

    public AmenityBookingRepository(AmenityDbContext context)
    {
        _context = context;
    }

    public async Task<AmenityBooking?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Include(b => b.Amenity)
            .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyList<AmenityBooking>> GetByAmenityAndDateAsync(
        Guid amenityId, 
        DateOnly date, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Include(b => b.Amenity)
            .Where(b => b.AmenityId == amenityId && b.BookingDate == date)
            .OrderBy(b => b.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AmenityBooking>> GetByAmenityAndDateRangeAsync(
        Guid amenityId, 
        DateOnly startDate, 
        DateOnly endDate, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Include(b => b.Amenity)
            .Where(b => b.AmenityId == amenityId && 
                        b.BookingDate >= startDate && 
                        b.BookingDate <= endDate)
            .OrderBy(b => b.BookingDate)
            .ThenBy(b => b.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AmenityBooking>> GetByUserAndSocietyAsync(
        Guid userId, 
        Guid societyId, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Include(b => b.Amenity)
            .Where(b => b.UserId == userId && b.SocietyId == societyId)
            .OrderByDescending(b => b.BookingDate)
            .ThenByDescending(b => b.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AmenityBooking>> GetByUserAndDateAsync(
        Guid userId, 
        DateOnly date, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Where(b => b.UserId == userId && b.BookingDate == date)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AmenityBooking>> GetBySocietyAndDateAsync(
        Guid societyId, 
        DateOnly date, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Include(b => b.Amenity)
            .Where(b => b.SocietyId == societyId && b.BookingDate == date)
            .OrderBy(b => b.Amenity!.Name)
            .ThenBy(b => b.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AmenityBooking>> GetPendingBySocietyAsync(
        Guid societyId, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .Include(b => b.Amenity)
            .Where(b => b.SocietyId == societyId && b.Status == BookingStatus.Pending)
            .OrderBy(b => b.BookingDate)
            .ThenBy(b => b.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<int> CountUserBookingsForDateAsync(
        Guid userId, 
        Guid amenityId, 
        DateOnly date, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .CountAsync(b => b.UserId == userId && 
                            b.AmenityId == amenityId && 
                            b.BookingDate == date &&
                            b.Status != BookingStatus.Cancelled &&
                            b.Status != BookingStatus.Rejected,
                            cancellationToken);
    }

    public async Task<bool> HasOverlappingBookingAsync(
        Guid amenityId, 
        DateOnly date, 
        TimeOnly startTime, 
        TimeOnly endTime, 
        CancellationToken cancellationToken = default)
    {
        return await _context.AmenityBookings
            .AnyAsync(b => b.AmenityId == amenityId &&
                          b.BookingDate == date &&
                          b.Status != BookingStatus.Cancelled &&
                          b.Status != BookingStatus.Rejected &&
                          b.StartTime < endTime &&
                          b.EndTime > startTime,
                          cancellationToken);
    }

    public void Add(AmenityBooking booking)
    {
        _context.AmenityBookings.Add(booking);
    }

    public void Update(AmenityBooking booking)
    {
        _context.AmenityBookings.Update(booking);
    }
}