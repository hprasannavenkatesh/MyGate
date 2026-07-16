using System;

namespace TenantService.Domain.Entities;

public class Flat
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid BlockId { get; private set; }
    public string FlatNumber { get; private set; } = null!; // e.g., "101"
    public string Type { get; private set; } = null!; // e.g., "2BHK"

    public virtual Block? Block { get; private set; }

    private Flat() { }

    public Flat(Guid blockId, string flatNumber, string type)
    {
        if (string.IsNullOrWhiteSpace(flatNumber)) throw new ArgumentException("Flat number is required.");

        Id = Guid.NewGuid();
        BlockId = blockId;
        FlatNumber = flatNumber;
        Type = type;
    }
}