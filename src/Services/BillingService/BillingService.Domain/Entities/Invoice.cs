using System;

namespace BillingService.Domain.Entities;

public class Invoice
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid SocietyId { get; private set; }
    public Guid FlatId { get; private set; }
    
    public decimal Amount { get; private set; }
    public decimal PenaltyAmount { get; private set; }
    public decimal TotalAmount => Amount + PenaltyAmount;
    
    public DateTime DueDate { get; private set; }
    public string? InvoiceNumber { get; private set; }
    public string? Description { get; private set; }
    
    public InvoiceStatus Status { get; private set; } = InvoiceStatus.Pending;
    public DateTime GeneratedAt { get; private set; }

    private Invoice() { }

    public Invoice(Guid societyId, Guid flatId, decimal amount, DateTime dueDate, string? description = null)
    {
        if (amount < 0) throw new ArgumentException("Amount cannot be negative.");
        
        Id = Guid.NewGuid();
        SocietyId = societyId;
        FlatId = flatId;
        Amount = amount;
        DueDate = dueDate;
        Description = description;
        GeneratedAt = DateTime.UtcNow;
    }

    public void MarkAsPaid(decimal penaltyPaid = 0)
    {
        Status = InvoiceStatus.Paid;
        PenaltyAmount = penaltyPaid; // In a real app, this would calculate based on days late
    }
}