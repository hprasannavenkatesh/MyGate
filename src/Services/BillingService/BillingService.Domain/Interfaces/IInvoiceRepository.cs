using BillingService.Domain.Entities;

namespace BillingService.Domain.Interfaces;

public interface IInvoiceRepository
{
    Task<Invoice> AddAsync(Invoice invoice);
    Task<List<Invoice>> GetByFlatIdAsync(Guid flatId);
}