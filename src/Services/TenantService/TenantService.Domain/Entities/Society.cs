using System;

namespace TenantService.Domain.Entities;

public class Society
{
    public Guid Id { get; private set; } = Guid.Empty;
    public string Name { get; private set; } = null!;
    public string Code { get; private set; } = null!; // e.g., "SUN-APT"
    public string Address { get; private set; } = null!;
    public string City { get; private set; } = null!;
    
    private Society() { }

    public Society(string name, string code, string address, string city)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Society name is required.");
        if (string.IsNullOrWhiteSpace(code)) throw new ArgumentException("Society code is required.");

        Id = Guid.NewGuid();
        Name = name;
        Code = code;
        Address = address;
        City = city;
    }
}