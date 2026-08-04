using AmenityService.Domain.Entities;

namespace AmenityService.Domain.Interfaces;

public interface IAmenityRepository
{
    Task<Amenity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Amenity>> GetBySocietyIdAsync(Guid societyId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Amenity>> GetActiveBySocietyIdAsync(Guid societyId, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> IsOwnedBySocietyAsync(Guid amenityId, Guid societyId, CancellationToken cancellationToken = default);
    void Add(Amenity amenity);
    void Update(Amenity amenity);
    void Remove(Amenity amenity);
}