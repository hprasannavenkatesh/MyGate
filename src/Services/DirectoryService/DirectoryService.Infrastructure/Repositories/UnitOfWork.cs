using DirectoryService.Domain.Interfaces;
using DirectoryService.Infrastructure.Data;

namespace DirectoryService.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly DirectoryDbContext _context;
    public IDirectoryRepository Directory { get; }

    public UnitOfWork(DirectoryDbContext context, IDirectoryRepository directoryRepo)
    {
        _context = context;
        Directory = directoryRepo;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) => await _context.SaveChangesAsync(cancellationToken);
    public void Dispose() { _context.Dispose(); GC.SuppressFinalize(this); }
}