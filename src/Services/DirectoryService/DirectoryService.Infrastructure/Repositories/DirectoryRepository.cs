using DirectoryService.Domain.Entities;
using DirectoryService.Domain.Interfaces;
using DirectoryService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DirectoryService.Infrastructure.Repositories;

public class DirectoryRepository : IDirectoryRepository
{
    private readonly DirectoryDbContext _context;
    public DirectoryRepository(DirectoryDbContext context) => _context = context;

    public async Task<DirectoryEntry?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.DirectoryEntries.FirstOrDefaultAsync(e => e.Id == id, cancellationToken);

    public async Task<IReadOnlyList<string>> GetCategoriesAsync(Guid societyId, CancellationToken cancellationToken = default)
        => await _context.DirectoryEntries
            .Where(e => e.SocietyId == societyId && e.IsActive)
            .Select(e => e.Category)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<DirectoryEntry>> GetBySocietyAsync(Guid societyId, string? category = null, string? searchQuery = null, CancellationToken cancellationToken = default)
    {
        var query = _context.DirectoryEntries.Where(e => e.SocietyId == societyId && e.IsActive);

        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(e => e.Category == category);

        if (!string.IsNullOrWhiteSpace(searchQuery))
            query = query.Where(e => e.Name.Contains(searchQuery) || e.ContactNumber.Contains(searchQuery));

        return await query.OrderBy(e => e.Category).ThenBy(e => e.Name).ToListAsync(cancellationToken);
    }

    public void Add(DirectoryEntry entry) => _context.DirectoryEntries.Add(entry);
    public void Update(DirectoryEntry entry) => _context.DirectoryEntries.Update(entry);
    public void Remove(DirectoryEntry entry) => _context.DirectoryEntries.Remove(entry);
}