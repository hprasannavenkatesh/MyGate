using HelpdeskService.Domain.Entities;

namespace HelpdeskService.Domain.Interfaces;

public interface ITicketRepository
{
    Task<Ticket> AddAsync(Ticket ticket);
    Task<List<Ticket>> GetByFlatIdAsync(Guid flatId);

      // NEW METHODS:
    Task<Ticket?> GetByIdWithCommentsAsync(Guid ticketId);
    Task AddCommentAsync(TicketComment comment);
    Task UpdateAsync(Ticket ticket);
}