using MediatR;

namespace BillingService.Application.Features.Invoices.Commands;

public class GenerateInvoiceCommand : IRequest<Guid>
{
    public Guid SocietyId { get; set; }
    public Guid FlatId { get; set; }
    public decimal Amount { get; set; }
    public DateTime DueDate { get; set; }
    public string? Description { get; set; }
}