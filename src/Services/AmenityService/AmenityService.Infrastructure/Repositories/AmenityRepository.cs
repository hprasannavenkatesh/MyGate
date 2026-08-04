using AmenityService.Domain.Entities;
using AmenityService.Domain.Interfaces;
using AmenityService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace AmenityService.Infrastructure.Repositories;

public class AmenityRepository : IAmenityRepository
{
    private readonly AmenityDbContext _context;

    public AmenityRepository(AmenityDbContext context)
    {
        _context = context;
    }

    public async Task<Amenity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Amenities
            .FirstOrDefaultAsync(a => a.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyList<Amenity>> GetBySocietyIdAsync(Guid societyId, CancellationToken cancellationToken = default)
    {
        return await _context.Amenities
            .Where(a => a.SocietyId == societyId)
            .OrderBy(a => a.Name)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Amenity>> GetActiveBySocietyIdAsync(Guid societyId, CancellationToken cancellationToken = default)
    {
        return await _context.Amenities
            .Where(a => a.SocietyId == societyId && a.IsActive)
            .OrderBy(a => a.Name)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Amenities
            .AnyAsync(a => a.Id == id, cancellationToken);
    }

    public async Task<bool> IsOwnedBySocietyAsync(Guid amenityId, Guid societyId, CancellationToken cancellationToken = default)
    {
        return await _context.Amenities
            .AnyAsync(a => a.Id == amenityId && a.SocietyId == societyId, cancellationToken);
    }

    public void Add(Amenity amenity)
    {
        _context.Amenities.Add(amenity);
    }

    public void Update(Amenity amenity)
    {
        _context.Amenities.Update(amenity);
    }

    public void Remove(Amenity amenity)
    {
        _context.Amenities.Remove(amenity);
    }
}