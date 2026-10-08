using BuildingBlocks.Messaging.Events;
using BuildingBlocks.Messaging.Interfaces;
using IdentityService.Domain.Entities;
using IdentityService.Domain.Interfaces;
using MediatR;

namespace IdentityService.Application.Features.Auth.Commands;

public class RegisterUserCommandHandler : IRequestHandler<RegisterUserCommand, Guid>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher; // NEW!
    private readonly IEventBus _eventBus; // 1. Declare it here


    // The database tool is automatically given to us by .NET's dependency injection
    public RegisterUserCommandHandler(IUserRepository userRepository, IPasswordHasher passwordHasher, IEventBus eventBus)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher; // NEW!
        _eventBus = eventBus; // NEW!
    }

    public async Task<Guid> Handle(RegisterUserCommand request, CancellationToken cancellationToken)
    {
        // BUSINESS RULE: Check if mobile is already registered (Rule ID-001 from our list!)
        //var exists = await _userRepository.ExistsByMobileAsync(request.MobileNumber);
        var exists = await _userRepository.GetByMobileAsync(request.MobileNumber);
       /* if (exists)
        {
            throw new InvalidOperationException("A user with this mobile number already exists.");
        }*/
         if (exists != null)
        {
            // ✅ CHANGED: Instead of throwing an exception, just return their ID.
            // This prevents the React UI from crashing if they search for a user, 
            // don't find them, and try to register them anyway.
            return exists.Id; 
        }


        // Create our Domain Entity 
        var user = new User(request.MobileNumber, request.FullName, request.Email);

        // NEW: Hash the password and set it on the user!
        user.SetPasswordHash(_passwordHasher.HashPassword(request.Password));

        user.AssignRole(request.Role); // Assign the role from the request

        if (request.Role != "Resident")
        {
            user.VerifyMobile(); // Auto-verify non-residents (like Admins or Guards)
        }

        // Save to database (via the interface)
        var addedUser = await _userRepository.AddAsync(user);


        // ==========================================
        // SHOUT INTO THE VOID!
        // ==========================================
        var eventMessage = new UserRegisteredEvent(
            addedUser.Id,
            addedUser.MobileNumber,
            addedUser.FullName,
            addedUser.CreatedAt
        );

        // "user-events" is the name of the radio station (topic)
        await _eventBus.PublishAsync(eventMessage, "user-events");
        // ==========================================

        // Return the new ID back to the API
        return addedUser.Id;
    }
}