using DirectoryService.Domain.Entities;

namespace DirectoryService.Domain.Interfaces;

public interface IDirectoryRepository
{
    Task<DirectoryEntry?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<string>> GetCategoriesAsync(Guid societyId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DirectoryEntry>> GetBySocietyAsync(Guid societyId, string? category = null, string? searchQuery = null, CancellationToken cancellationToken = default);
    void Add(DirectoryEntry entry);
    void Update(DirectoryEntry entry);
    void Remove(DirectoryEntry entry);
}