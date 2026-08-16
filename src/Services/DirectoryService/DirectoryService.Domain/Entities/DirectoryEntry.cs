namespace DirectoryService.Domain.Entities;

public class DirectoryEntry : BaseEntity
{
    public Guid SocietyId { get; private set; }
    public string Category { get; private set; } = string.Empty; // "Committee", "Emergency", "Plumber", "Electrician"
    public string Name { get; private set; } = string.Empty;
    public string ContactNumber { get; private set; } = string.Empty;
    public string? Email { get; private set; }
    public string? Address { get; private set; }
    public string? Notes { get; private set; }
    public bool IsActive { get; private set; } = true;

    private DirectoryEntry() { }

    public static DirectoryEntry Create(Guid societyId, string category, string name, string contactNumber, string? email, string? address, string? notes)
    {
        if (string.IsNullOrWhiteSpace(category)) throw new ArgumentException("Category is required.");
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name is required.");
        if (string.IsNullOrWhiteSpace(contactNumber)) throw new ArgumentException("Contact number is required.");

        return new DirectoryEntry
        {
            SocietyId = societyId,
            Category = category.Trim(),
            Name = name.Trim(),
            ContactNumber = contactNumber.Trim(),
            Email = email?.Trim(),
            Address = address?.Trim(),
            Notes = notes?.Trim()
        };
    }

    public void Update(string category, string name, string contactNumber, string? email, string? address, string? notes)
    {
        Category = category.Trim();
        Name = name.Trim();
        ContactNumber = contactNumber.Trim();
        Email = email?.Trim();
        Address = address?.Trim();
        Notes = notes?.Trim();
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}