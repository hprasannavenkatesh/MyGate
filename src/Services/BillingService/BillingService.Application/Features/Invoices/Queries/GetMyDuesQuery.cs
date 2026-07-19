using MediatR;
using BillingService.Domain.Entities;

namespace BillingService.Application.Features.Invoices.Queries;

public class GetMyDuesQuery : IRequest<List<Invoice>>
{
    public Guid FlatId { get; set; }
}