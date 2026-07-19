using BillingService.Domain.Entities;
using BillingService.Domain.Interfaces;
using BillingService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BillingService.Infrastructure.Repositories;

public class InvoiceRepository : IInvoiceRepository
{
    private readonly BillingDbContext _context;
    public InvoiceRepository(BillingDbContext context) => _context = context;

    public async Task<Invoice> AddAsync(Invoice invoice)
    {
        await _context.Invoices.AddAsync(invoice);
        await _context.SaveChangesAsync();
        return invoice;
    }

    public async Task<List<Invoice>> GetByFlatIdAsync(Guid flatId)
    {
        return await _context.Invoices
            .Where(i => i.FlatId == flatId)
            .OrderByDescending(i => i.DueDate)
            .ToListAsync();
    }
}