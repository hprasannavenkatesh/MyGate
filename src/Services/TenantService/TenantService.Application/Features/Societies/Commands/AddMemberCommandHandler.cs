using MediatR;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;


namespace TenantService.Application.Features.Societies.Commands;

public class AddMemberCommandHandler : IRequestHandler<AddMemberCommand, Guid>
{
    private readonly ISocietyMemberRepository _repository;

    public AddMemberCommandHandler(ISocietyMemberRepository repository)
    {
        _repository = repository;
    }

    /*
        public async Task<Guid> Handle(AddMemberCommand request, CancellationToken cancellationToken)
        {
            // 1. Parse the string to our Enum
            if (!Enum.TryParse<MemberType>(request.MemberType, out var memberType))
            {
                throw new ArgumentException($"Invalid MemberType: {request.MemberType}");
            }

     // ✨ NEW Business Rule: The "One Primary Per Flat" Rule
            if (request.IsPrimary)
            {
                  Console.WriteLine($"🔍 DEBUG: Checking for existing Primary on FlatId: {request.FlatId}");


                // Fetch all existing members for this specific flat
                var existingMembers = await _repository.GetByFlatIdAsync(request.FlatId, cancellationToken);

                // Find the current Primary member (if any)
                var currentPrimary = existingMembers.FirstOrDefault(m => m.IsPrimary);

                if (currentPrimary != null)
                {
                    // Demote the current primary to Co-Owner automatically to prevent duplicates
                    currentPrimary.UpdateMemberType(MemberType.CoOwner); // Assuming you have a CoOwner enum
                    currentPrimary.SetPrimary(false); // Assuming you have a setter for IsPrimary

                    _repository.Update(currentPrimary);
                      // ✅ CRITICAL FIX: We MUST save the demotion to the database 
                    // BEFORE adding the new primary member!
                    await _repository.SaveChangesAsync(cancellationToken);
                     // This prevents the second SaveChanges from overwriting our demotion!
                    Console.WriteLine($"✅ DEMOTION SAVED: Old primary is now demoted.");
                }
                 else
                {
                    Console.WriteLine($"✅ DEBUG: No existing Primary found. Safe to assign.");
                }
            }

            // 2. Use our Domain Entity to create the record
            var member = new SocietyMember(
                request.SocietyId,
                request.UserId,
                request.FlatId,
                memberType,
                request.IsPrimary
            );

            // 3. Save to database
            var result = await _repository.AddAsync(member);

            return result.Id;
        }
        */

    public async Task<Guid> Handle(AddMemberCommand request, CancellationToken cancellationToken)
    {
        // 1. Parse the string to our Enum
        if (!Enum.TryParse<MemberType>(request.MemberType, out var memberType))
        {
            throw new ArgumentException($"Invalid MemberType: {request.MemberType}");
        }

       

        // ✨ 4. Business Rule: The "One Primary Per Flat" Rule
        // We check and demote AFTER adding the new member to the EF Core context,
        // but BEFORE calling SaveChanges. This keeps the tracker clean.
        if (request.IsPrimary)
        {
            var existingMembers = await _repository.GetByFlatIdAsync(request.FlatId, cancellationToken);
           /* var currentPrimary = existingMembers.FirstOrDefault(m => m.IsPrimary);

            if (currentPrimary != null)
            {
                // Demote the old primary to Co-Owner automatically
                currentPrimary.UpdateMemberType(MemberType.CoOwner);
                currentPrimary.SetPrimary(false);
                _repository.Update(currentPrimary);
                await _repository.SaveChangesAsync(cancellationToken);
            }*/
             var currentPrimaries = existingMembers.Where(m => m.IsPrimary).ToList();
            
            if (currentPrimaries.Any())
            {
                foreach (var primary in currentPrimaries)
                {
                    primary.UpdateMemberType(MemberType.CoOwner); 
                    primary.SetPrimary(false); 
                    _repository.Update(primary);
                }
                
                // Save ALL the demotions to the database BEFORE adding the new member
                await _repository.SaveChangesAsync(cancellationToken);
            }
        }

        // 5. Save everything in one single transaction
       // await _repository.SaveChangesAsync(cancellationToken);
        // 2. Create the new member entity
        var member = new SocietyMember(
            request.SocietyId,
            request.UserId,
            request.FlatId,
            memberType,
            request.IsPrimary
        );

        // 3. Add to context (DO NOT SAVE YET)
         var result = await _repository.AddAsync(member);

        return result.Id;
    }
}