namespace BillingService.Domain.Entities;

public enum InvoiceStatus
{
    Pending,    // Just generated
    Paid,       // Resident paid
    Overdue,    // Past due date
    Waived,      // Admin removed the charge
    PartiallyPaid // Advanced paid, but not full amount
}