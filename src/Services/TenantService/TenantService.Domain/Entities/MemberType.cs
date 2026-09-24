namespace TenantService.Domain.Entities;

public enum MemberType
{
    Owner,
    Tenant,
    FamilyMemberOfOwner,
    FamilyMemberOfTenant,
      CommitteeMember = 4   // <--- ADD THIS FOR ADMIN ACCESS
}