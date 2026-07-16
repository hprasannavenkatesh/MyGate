using System;

namespace TenantService.Domain.Entities;

public class SocietyMember
{
    public Guid Id { get; private set; } = Guid.Empty;
    public Guid SocietyId { get; private set; }
    public Guid UserId { get; private set; } // This comes from IdentityService!
    public Guid FlatId { get; private set; }
    public MemberType MemberType { get; private set; }
    public bool IsPrimary { get; private set; }
    
    public virtual Flat? Flat { get; private set; }

    private SocietyMember() { }

    public SocietyMember(Guid societyId, Guid userId, Guid flatId, MemberType memberType, bool isPrimary = false)
    {
        Id = Guid.NewGuid();
        SocietyId = societyId;
        UserId = userId;
        FlatId = flatId;
        MemberType = memberType;
        IsPrimary = isPrimary;
    }
}