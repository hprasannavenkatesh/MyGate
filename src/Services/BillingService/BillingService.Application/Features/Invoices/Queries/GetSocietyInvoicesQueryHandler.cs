using MediatR;
using BillingService.Domain.Interfaces;
using BillingService.Domain.Entities;

namespace BillingService.Application.Features.Invoices.Queries;

public class GetSocietyInvoicesQueryHandler : IRequestHandler<GetSocietyInvoicesQuery, List<Invoice>>
{
    private readonly IInvoiceRepository _repository;
    public GetSocietyInvoicesQueryHandler(IInvoiceRepository repository) => _repository = repository;

    public async Task<List<Invoice>> Handle(GetSocietyInvoicesQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetBySocietyIdAsync(request.SocietyId);
    }
}