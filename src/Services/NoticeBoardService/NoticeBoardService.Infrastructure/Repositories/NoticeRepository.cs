using Microsoft.EntityFrameworkCore;
using NoticeBoardService.Domain.Entities;
using NoticeBoardService.Domain.Interfaces;
using NoticeBoardService.Infrastructure.Persistence;

namespace NoticeBoardService.Infrastructure.Repositories;

public class NoticeRepository : INoticeRepository
{
    private readonly NoticeBoardDbContext _context;
    public NoticeRepository(NoticeBoardDbContext context) => _context = context;

    public async Task<Notice> AddAsync(Notice notice)
    {
        await _context.Notices.AddAsync(notice);
        await _context.SaveChangesAsync();
        return notice;
    }

    public async Task<Notice?> GetByIdAsync(Guid id)
    {
        return await _context.Notices.FindAsync(id);
    }

    public async Task<IReadOnlyList<Notice>> GetBySocietyAsync(Guid societyId)
    {
        // Pinned notices first, then by newest date
        return await _context.Notices
            .Where(n => n.SocietyId == societyId)
            .OrderByDescending(n => n.IsPinned)
            .ThenByDescending(n => n.CreatedAt)
            .ToListAsync();
    }
}