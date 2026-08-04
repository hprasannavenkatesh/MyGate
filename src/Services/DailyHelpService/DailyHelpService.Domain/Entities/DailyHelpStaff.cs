namespace DailyHelpService.Domain.Entities;

public class DailyHelpStaff : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string MobileNumber { get; private set; } = string.Empty;
    public Guid HelpTypeId { get; private set; }
    public string? AgencyName { get; private set; }
    public bool IsActive { get; private set; } = true;
    
    public virtual HelpType HelpType { get; private set; } = null!;
    public virtual ICollection<DailyHelpAssignment> Assignments { get; private set; } = new List<DailyHelpAssignment>();

    private DailyHelpStaff() { }

    public static DailyHelpStaff Create(Guid societyId, string name, string mobileNumber, Guid helpTypeId, string? agencyName)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name is required.");
        if (string.IsNullOrWhiteSpace(mobileNumber) || mobileNumber.Length < 10) throw new ArgumentException("Valid mobile number is required.");

        return new DailyHelpStaff
        {
            SocietyId = societyId,
            Name = name.Trim(),
            MobileNumber = mobileNumber.Trim(),
            HelpTypeId = helpTypeId,
            AgencyName = agencyName?.Trim()
        };
    }

    public void Update(string name, string mobileNumber, Guid helpTypeId, string? agencyName)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name is required.");
        Name = name.Trim();
        MobileNumber = mobileNumber.Trim();
        HelpTypeId = helpTypeId;
        AgencyName = agencyName?.Trim();
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Deactivate() { IsActive = false; UpdatedAt = DateTimeOffset.UtcNow; }
    public void Activate() { IsActive = true; UpdatedAt = DateTimeOffset.UtcNow; }
}