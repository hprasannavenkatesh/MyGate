using DailyHelpService.Domain.Entities;
using DailyHelpService.Domain.Interfaces;
using DailyHelpService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DailyHelpService.Infrastructure.Repositories;

public class HelpTypeRepository : IHelpTypeRepository
{
    private readonly DailyHelpDbContext _context;
    public HelpTypeRepository(DailyHelpDbContext context) => _context = context;

    public async Task<HelpType?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.HelpTypes.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public async Task<IReadOnlyList<HelpType>> GetBySocietyAsync(Guid societyId, CancellationToken cancellationToken = default)
        => await _context.HelpTypes.Where(t => t.SocietyId == societyId).OrderBy(t => t.Name).ToListAsync(cancellationToken);

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
        => await _context.HelpTypes.AnyAsync(t => t.Id == id, cancellationToken);

    public void Add(HelpType helpType) => _context.HelpTypes.Add(helpType);
    public void Update(HelpType helpType) => _context.HelpTypes.Update(helpType);
}