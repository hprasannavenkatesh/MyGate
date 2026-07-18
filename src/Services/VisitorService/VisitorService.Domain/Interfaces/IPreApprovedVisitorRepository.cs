using VisitorService.Domain.Entities;

namespace VisitorService.Domain.Interfaces;

public interface IPreApprovedVisitorRepository
{
    Task<PreApprovedVisitor> AddAsync(PreApprovedVisitor visitor);
    Task<PreApprovedVisitor?> GetByIdAsync(Guid id);
        Task<List<PreApprovedVisitor>> GetByInviterIdAsync(Guid inviterId);
}