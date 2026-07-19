using MediatR;
using BillingService.Domain.Entities;
using BillingService.Domain.Interfaces;

namespace BillingService.Application.Features.Invoices.Commands;

public class GenerateInvoiceCommandHandler : IRequestHandler<GenerateInvoiceCommand, Guid>
{
    private readonly IInvoiceRepository _repository;
    public GenerateInvoiceCommandHandler(IInvoiceRepository repository) => _repository = repository;

    public async Task<Guid> Handle(GenerateInvoiceCommand request, CancellationToken cancellationToken)
    {
        var invoice = new Invoice(
            request.SocietyId, 
            request.FlatId, 
            request.Amount, 
            request.DueDate, 
            request.Description
        );

        return (await _repository.AddAsync(invoice)).Id;
    }
}