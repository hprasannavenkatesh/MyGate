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
    }
}