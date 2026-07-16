using System;

namespace TenantService.Domain.Entities;

public class Block
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid SocietyId { get; private set; }
    public string Name { get; private set; } = null!; // e.g., "A", "B"
    
    // Navigation property (EF Core will use this to link tables)
    public virtual Society? Society { get; private set; }

    private Block() { }

    public Block(Guid societyId, string name)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Block name is required.");
        
        Id = Guid.NewGuid();
        SocietyId = societyId;
        Name = name;
    }
}