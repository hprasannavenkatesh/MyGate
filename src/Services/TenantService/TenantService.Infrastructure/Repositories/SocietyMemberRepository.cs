using TenantService.Domain;
using TenantService.Domain.Interfaces;
using TenantService.Domain.Entities;
using TenantService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace TenantService.Infrastructure.Repositories;

public class SocietyMemberRepository : ISocietyMemberRepository
{
    private readonly TenantDbContext _context;

    public SocietyMemberRepository(TenantDbContext context)
    {
        _context = context;
    }

    public async Task<List<UserSocietyDto>> GetByUserIdAsync(Guid userId)
    {
        // Here we use LINQ to join Members -> Flats -> Blocks -> Societies!
        return await _context.SocietyMembers
            .Where(m => m.UserId == userId)
            .Include(m => m.Flat!)         // Tell EF Core to load the Flat
            .ThenInclude(f => f.Block!)    // Tell EF Core to load the Block inside the Flat
            .ThenInclude(b => b.Society!)  // Tell EF Core to load the Society inside the Block
            .Select(m => new UserSocietyDto
            {
                SocietyId = m.SocietyId,
                SocietyName = m.Flat!.Block!.Society!.Name,
                FlatId = m.FlatId,
                FlatNumber = m.Flat.FlatNumber,
                BlockName = m.Flat.Block.Name,
                MemberType = m.MemberType.ToString()
            })
            .ToListAsync();
    }

    public async Task<SocietyMember> AddAsync(SocietyMember member)
    {
        await _context.SocietyMembers.AddAsync(member);
        await _context.SaveChangesAsync();
        return member;
    }

    public void Update(SocietyMember member) => _context.SocietyMembers.Update(member);

    public async Task<IReadOnlyList<SocietyMember>> GetByFlatIdAsync(Guid flatId, CancellationToken cancellationToken = default)
    {
        return await _context.SocietyMembers
            .Where(m => m.FlatId == flatId)
            .ToListAsync(cancellationToken);
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    // ADD:
    public async Task<IReadOnlyList<SocietyMember>> GetBySocietyIdAsync(Guid societyId, CancellationToken cancellationToken = default)
    {
        return await _context.SocietyMembers
            .Where(m => m.SocietyId == societyId)
            .ToListAsync(cancellationToken);
    }

    public void Remove(SocietyMember member) => _context.SocietyMembers.Remove(member);
}