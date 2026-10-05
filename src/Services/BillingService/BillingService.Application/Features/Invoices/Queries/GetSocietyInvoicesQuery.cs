using MediatR;
using BillingService.Domain.Entities;

namespace BillingService.Application.Features.Invoices.Queries;

public class GetSocietyInvoicesQuery : IRequest<List<Invoice>>
{
    public Guid SocietyId { get; set; }
}