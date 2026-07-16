using TenantService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace TenantService.Infrastructure.Persistence;

public class TenantDbContext : DbContext
{
    public TenantDbContext(DbContextOptions<TenantDbContext> options) : base(options)
    {
    }

    // One DbSet for each table we want in SQL Server
    public DbSet<Society> Societies => Set<Society>();
    public DbSet<Block> Blocks => Set<Block>();
    public DbSet<Flat> Flats => Set<Flat>();
    public DbSet<SocietyMember> SocietyMembers => Set<SocietyMember>();
}