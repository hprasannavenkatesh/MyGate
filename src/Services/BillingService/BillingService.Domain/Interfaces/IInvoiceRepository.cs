using BillingService.Domain.Entities;

namespace BillingService.Domain.Interfaces;

public interface IInvoiceRepository
{
    Task<Invoice> AddAsync(Invoice invoice);
    Task<List<Invoice>> GetByFlatIdAsync(Guid flatId);
    // ADD this method:
    Task<List<Invoice>> GetBySocietyIdAsync(Guid societyId);

     void Add(Invoice invoice); // Adds to EF Core context without saving
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default); // Saves all at once
}