using NoticeBoardService.Domain.Entities;

namespace NoticeBoardService.Domain.Interfaces;

public interface INoticeRepository
{
    Task<Notice> AddAsync(Notice notice);
    Task<IReadOnlyList<Notice>> GetBySocietyAsync(Guid societyId);
    Task<Notice?> GetByIdAsync(Guid id);
}