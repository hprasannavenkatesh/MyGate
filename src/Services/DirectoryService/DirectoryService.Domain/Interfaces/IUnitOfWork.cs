namespace DirectoryService.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IDirectoryRepository Directory { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}