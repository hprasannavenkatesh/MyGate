namespace TenantService.Domain.Entities;

public enum MemberType
{
    Owner,
    Tenant,
    FamilyMemberOfOwner,
    FamilyMemberOfTenant,
      CommitteeMember = 4,   // <--- ADD THIS FOR ADMIN ACCESS
       CoOwner = 5, // NEW: For spouses/demoted primaries
       Guard=6 //Security personnel who can manage visitors and access control

}