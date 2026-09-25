using VisitorService.Domain.Entities;

namespace VisitorService.Domain.Interfaces;

public interface IVisitorLogRepository
{
    Task<VisitorLog> AddAsync(VisitorLog log);
    Task<VisitorLog?> GetByIdAsync(Guid id);
        Task UpdateAsync(VisitorLog log);
         Task<VisitorLog?> GetActiveByPreApprovalIdAsync(Guid preApprovalId);
}