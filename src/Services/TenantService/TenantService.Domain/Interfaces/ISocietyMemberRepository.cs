using TenantService.Domain;
using TenantService.Domain.Entities;

namespace TenantService.Domain.Interfaces;

public interface ISocietyMemberRepository
{
    // We will use LINQ in the database to join the tables and return the exact DTO shape!
    Task<List<UserSocietyDto>> GetByUserIdAsync(Guid userId);

    // NEW: Method to add a member to a flat
    Task<SocietyMember> AddAsync(SocietyMember member);

    void Update(SocietyMember member);

    Task<IReadOnlyList<SocietyMember>> GetByFlatIdAsync(Guid flatId, CancellationToken cancellationToken = default);

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    // ADD:
    Task<IReadOnlyList<SocietyMember>> GetBySocietyIdAsync(Guid societyId, CancellationToken cancellationToken = default);
    void Remove(SocietyMember member);
}