using TenantService.Domain;
using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface ISocietyMemberRepository
{
    // We will use LINQ in the database to join the tables and return the exact DTO shape!
    Task<List<UserSocietyDto>> GetByUserIdAsync(Guid userId);

        // NEW: Method to add a member to a flat
    Task<SocietyMember> AddAsync(SocietyMember member);
}