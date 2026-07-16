namespace VisitorService.Domain.Entities;

public enum VisitorStatus
{
    Pending,   // Pre-approved, but hasn't arrived yet
    Inside,    // Guard marked them as entered
    Exited,    // Guard marked them as exited
    Expired    // The expected date passed and they never showed up
}