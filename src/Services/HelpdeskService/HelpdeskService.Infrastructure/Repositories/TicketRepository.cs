using HelpdeskService.Domain.Entities;
using HelpdeskService.Domain.Interfaces;
using HelpdeskService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace HelpdeskService.Infrastructure.Repositories;

public class TicketRepository : ITicketRepository
{
    private readonly HelpdeskDbContext _context;
    public TicketRepository(HelpdeskDbContext context) => _context = context;

    public async Task<Ticket> AddAsync(Ticket ticket)
    {
        await _context.Tickets.AddAsync(ticket);
        await _context.SaveChangesAsync();
        return ticket;
    }

    public async Task<List<Ticket>> GetByFlatIdAsync(Guid flatId)
    {
        return await _context.Tickets
            .Where(t => t.FlatId == flatId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();
    }
     // NEW METHODS IMPLEMENTATION:
    public async Task<Ticket?> GetByIdWithCommentsAsync(Guid ticketId)
    {
        return await _context.Tickets
            .Include(t => t.Comments) // This loads the comments!
            .FirstOrDefaultAsync(t => t.Id == ticketId);
    }

    public async Task AddCommentAsync(TicketComment comment)
    {
        await _context.TicketComments.AddAsync(comment);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(Ticket ticket)
    {
        _context.Tickets.Update(ticket);
        await _context.SaveChangesAsync();
    }
}