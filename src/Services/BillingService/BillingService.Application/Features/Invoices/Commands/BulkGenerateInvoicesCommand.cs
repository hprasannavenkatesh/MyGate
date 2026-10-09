using MediatR;

namespace BillingService.Application.Features.Invoices.Commands;

public class BulkGenerateInvoicesCommand : IRequest<int> // Returns count of invoices created
{
    public Guid SocietyId { get; set; }
    public decimal Amount { get; set; }
    public DateTime DueDate { get; set; }
    public string? Description { get; set; }
}