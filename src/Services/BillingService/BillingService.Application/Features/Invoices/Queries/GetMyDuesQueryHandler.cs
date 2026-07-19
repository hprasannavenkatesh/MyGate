using MediatR;
using BillingService.Domain.Interfaces;
using BillingService.Domain.Entities;

namespace BillingService.Application.Features.Invoices.Queries;

public class GetMyDuesQueryHandler : IRequestHandler<GetMyDuesQuery, List<Invoice>>
{
    private readonly IInvoiceRepository _repository;
    public GetMyDuesQueryHandler(IInvoiceRepository repository) => _repository = repository;

    public async Task<List<Invoice>> Handle(GetMyDuesQuery request, CancellationToken cancellationToken)
    {
        return await _repository.GetByFlatIdAsync(request.FlatId);
    }
}