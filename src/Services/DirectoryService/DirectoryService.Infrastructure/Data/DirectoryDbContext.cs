using DirectoryService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DirectoryService.Infrastructure.Data;

public class DirectoryDbContext : DbContext
{
    public DirectoryDbContext(DbContextOptions<DirectoryDbContext> options) : base(options) { }

    public DbSet<DirectoryEntry> DirectoryEntries => Set<DirectoryEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<DirectoryEntry>(entity =>
        {
            entity.ToTable("DirectoryEntries");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Category).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.ContactNumber).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Email).HasMaxLength(150);
            entity.Property(e => e.Address).HasMaxLength(200);
            entity.Property(e => e.Notes).HasMaxLength(500);
            
            entity.HasIndex(e => e.SocietyId);
            entity.HasIndex(e => new { e.SocietyId, e.Category });
        });
    }
}