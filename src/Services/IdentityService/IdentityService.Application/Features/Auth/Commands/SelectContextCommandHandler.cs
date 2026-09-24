using IdentityService.Domain.Interfaces;
using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class SelectContextCommandHandler : IRequestHandler<SelectContextCommand, string>
{
    private readonly IUserRepository _userRepository;
    private readonly ITokenService _tokenService;

    public SelectContextCommandHandler(IUserRepository userRepository, ITokenService tokenService)
    {
        _userRepository = userRepository;
        _tokenService = tokenService;
    }
    public async Task<string> Handle(SelectContextCommand request, CancellationToken cancellationToken)
    {
        // 1. FETCH REAL USER FROM IDENTITY DB
        // (Assuming you have a GetByIdAsync method in your repo)
        var user = await _userRepository.GetByIdAsync(request.UserId);

        if (user == null)
        {
            throw new UnauthorizedAccessException("User does not exist.");
        }

        // 2. MAP MEMBER TYPE TO ROLE STRING
        // React sends "0" for Admin, "1" for Resident (Based on our SQL script enum)
        /*string assignedRole = request.MemberType switch
        {
            "0" => "Admin",
            "1" => "Resident",
            "Admin" => "Admin", // Fallback if string is sent
            "Resident" => "Resident",
            _ => "Resident" // Security Default: If unknown, treat as Resident
        };*/
        // 1. Get MemberType from Request (e.g., 0, 1, 2)
        int memberTypeId = int.Parse(request.MemberType); // Assuming React sends "0", "1"

        // 2. Map MemberType to Security Role
        string assignedRole = memberTypeId switch
        {
            4 => "Admin",       // CommitteeMember gets Admin access
            0 => "Resident",    // Owner gets Resident access
            1 => "Resident",    // Tenant gets Resident access
            2 => "Resident",    // FamilyOfOwner gets Resident access
            3 => "Resident",    // FamilyOfTenant gets Resident access
            _ => "Resident"     // Default safe fallback for unknown types
        };

Console.WriteLine($"🔑 MAPPED ROLE IS: {assignedRole}"); // <--- ADD THIS LOG
        Console.WriteLine($"📱 Generating Context Token for User: {user.FullName} | Society: {request.SocietyId} | Role: {assignedRole}");

        // 3. GENERATE TOKEN WITH REAL DATA
        var fatToken = _tokenService.GenerateToken(
            request.UserId,
            user.MobileNumber, // FROM DB
            user.FullName,     // FROM DB
            request.SocietyId,
            request.FlatId,
            assignedRole       // MAPPED SECURELY
        );

        return fatToken;
    }

    /* public async Task<string> Handle(SelectContextCommand request, CancellationToken cancellationToken)
     {
         // 1. Verify the user actually exists
         // (In a real app with service-to-service calls, we'd ask the Tenant Service 
         // "Hey, does this user actually belong to this flat?". For now, we trust the Flutter app).
         var user = await _userRepository.GetByMobileAsync(""); // We'll just mock the user fetch for now

           // ==========================================
         // SECURE ROLE ASSIGNMENT (Backend decides, not Flutter!)
         // ==========================================
         string assignedRole = "Resident"; // Default: Everyone is a resident

         // TEMPORARY HARD CODE FOR TESTING: 
         // Replace this with your actual User ID from the SQL database!
         if (request.UserId == Guid.Parse("ECB0DB65-5C7B-4EA3-A79F-5FC2F33D1A30"))
         {
             assignedRole = "Admin";
         }
         // ==========================================
          Console.WriteLine($"📱 USER ID  {request.UserId}");
         // 2. Generate the FAT TOKEN with all the new context data!
         var fatToken = _tokenService.GenerateToken(
             request.UserId, 
             "dummy_mobile_for_now", // We would fetch this from DB
             "Dummy Name",           // We would fetch this from DB
             request.SocietyId, 
             request.FlatId, 
             request.MemberType,
             //request.Role
             assignedRole
         );

         return fatToken;
     }*/
}