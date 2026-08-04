using DailyHelpService.Domain.Entities;

namespace DailyHelpService.Domain.Interfaces;

public interface IDailyHelpStaffRepository
{
    Task<DailyHelpStaff?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DailyHelpStaff>> GetBySocietyAsync(Guid societyId, Guid? helpTypeId = null, CancellationToken cancellationToken = default);
    void Add(DailyHelpStaff staff);
    void Update(DailyHelpStaff staff);
}