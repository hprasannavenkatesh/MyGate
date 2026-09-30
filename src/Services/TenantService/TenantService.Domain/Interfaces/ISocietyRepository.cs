using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface ISocietyRepository
{
    Task<Society> AddAsync(Society society);
    Task<IReadOnlyList<Society>> GetAllAsync(CancellationToken ct = default);
    Task<Society?> GetByIdAsync(Guid id, CancellationToken ct = default); // ADDED
    void Add(Society society);
    void Update(Society society);
    void Delete(Society society);
      Task<int> SaveChangesAsync(CancellationToken ct = default); // <-- ADD THIS
}