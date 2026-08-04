namespace HelpdeskService.Domain.Entities;

public enum TicketStatus
{
    Open,        // Newly created
    InProgress,  // Admin is working on it
    Resolved,    // Admin fixed it, waiting for user review
    Closed,       // User confirmed it's fixed
    Rejected     // Admin couldn't fix or invalid ticket
}