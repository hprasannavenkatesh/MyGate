using IdentityService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace IdentityService.Infrastructure.Persistence;

public class IdentityDbContext : DbContext
{
    // This constructor is required by EF Core
    public IdentityDbContext(DbContextOptions<IdentityDbContext> options) : base(options)
    {
    }

    // This creates the "Users" table in SQL Server based on our User entity
    public DbSet<User> Users => Set<User>();
}