using IdentityService.Domain.Entities;

namespace IdentityService.Domain.Interfaces;

public interface IUserRepository
{
    Task<User> AddAsync(User user);
    Task<bool> ExistsByMobileAsync(string mobileNumber);

    // NEW: Get user by mobile number
    Task<User?> GetByMobileAsync(string mobileNumber);
    Task<User?> GetByIdAsync(Guid userId);

    Task UpdateAsync(User user);
}