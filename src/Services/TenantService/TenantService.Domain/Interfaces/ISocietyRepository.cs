using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface ISocietyRepository
{
    Task<Society> AddAsync(Society society);
}