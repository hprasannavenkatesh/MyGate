namespace DailyHelpService.Domain.Entities;

public class HelpType : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    
    public virtual ICollection<DailyHelpStaff> Staff { get; private set; } = new List<DailyHelpStaff>();

    private HelpType() { }

    public static HelpType Create(Guid societyId, string name)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Help type name is required.");
        return new HelpType { SocietyId = societyId, Name = name.Trim() };
    }

    public void Update(string name)
    {
        Name = name.Trim();
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}