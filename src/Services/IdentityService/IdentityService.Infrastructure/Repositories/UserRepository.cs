using IdentityService.Domain.Entities;
using IdentityService.Domain.Interfaces;
using IdentityService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace IdentityService.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly IdentityDbContext _context;

    // The database context is automatically given to us by .NET
    public UserRepository(IdentityDbContext context)
    {
        _context = context;
    }

    public async Task<User> AddAsync(User user)
    {
        // Tell EF Core to add the user to the database
        await _context.Users.AddAsync(user);
        
        // Actually execute the save to SQL Server
        await _context.SaveChangesAsync();
        
        // Return the user (which now has its generated ID)
        return user;
    }

    public async Task<bool> ExistsByMobileAsync(string mobileNumber)
    {
        // Check if ANY user in the Users table has this mobile number
        return await _context.Users
            .AnyAsync(u => u.MobileNumber == mobileNumber);
    }

        public async Task<User?> GetByMobileAsync(string mobileNumber)
    {
        // Find the user. '?' means it returns null if not found
        return await _context.Users
            .FirstOrDefaultAsync(u => u.MobileNumber == mobileNumber);
    }

        public async Task<User?> GetByIdAsync(Guid userId)
    {
        return await _context.Users.FindAsync(userId);
    }

        public async Task UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }
}