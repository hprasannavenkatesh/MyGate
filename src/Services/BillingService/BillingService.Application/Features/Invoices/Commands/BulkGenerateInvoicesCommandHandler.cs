using System.Text.Json;
using MediatR;
using BillingService.Domain.Entities;
using BillingService.Domain.Interfaces;
using Microsoft.Extensions.Http;

namespace BillingService.Application.Features.Invoices.Commands;

public class BulkGenerateInvoicesCommandHandler : IRequestHandler<BulkGenerateInvoicesCommand, int>
{
    private readonly IInvoiceRepository _invoiceRepo;
    private readonly IHttpClientFactory _httpClientFactory;

    public BulkGenerateInvoicesCommandHandler(IInvoiceRepository invoiceRepo,IHttpClientFactory httpClientFactory)
    {
        _invoiceRepo = invoiceRepo;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<int> Handle(BulkGenerateInvoicesCommand request, CancellationToken cancellationToken)
    {
        // 1. Call TenantService API to get all blocks for the society
        var client = _httpClientFactory.CreateClient("TenantService");
        var response = await client.GetAsync($"api/Societies/{request.SocietyId}/blocks", cancellationToken);
        
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException("Failed to fetch blocks from TenantService.");

        var blocksJson = await response.Content.ReadAsStringAsync(cancellationToken);
        
        // Parse the response to get Block IDs
        using var doc = JsonDocument.Parse(blocksJson);
        var blockIds = doc.RootElement.EnumerateArray()
            .Select(b => b.GetProperty("id").GetGuid())
            .ToList();

        int invoicesCreated = 0;

        // 2. For each block, call TenantService to get its flats
        foreach (var blockId in blockIds)
        {
            var flatsResponse = await client.GetAsync($"api/Societies/blocks/{blockId}/flats", cancellationToken);
            if (!flatsResponse.IsSuccessStatusCode) continue;

            var flatsJson = await flatsResponse.Content.ReadAsStringAsync(cancellationToken);
            using var flatsDoc = JsonDocument.Parse(flatsJson);
            
            var flatIds = flatsDoc.RootElement.EnumerateArray()
                .Select(f => f.GetProperty("id").GetGuid())
                .ToList();

            // 3. For each flat, create the invoice in memory
            foreach (var flatId in flatIds)
            {
                var invoice = new Invoice(
                    request.SocietyId,
                    flatId,
                    request.Amount,
                    request.DueDate,
                    request.Description
                );
                
                _invoiceRepo.Add(invoice); // Add to EF Core context (no DB hit yet)
                invoicesCreated++;
            }
        }

        // 4. Save ALL invoices to the database in one single transaction
        if (invoicesCreated > 0)
        {
            await _invoiceRepo.SaveChangesAsync(cancellationToken);
        }

        return invoicesCreated;
    }
}