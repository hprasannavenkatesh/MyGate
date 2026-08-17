using EmergencyService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EmergencyService.Infrastructure.Data;

public class EmergencyDbContext : DbContext
{
    public EmergencyDbContext(DbContextOptions<EmergencyDbContext> options) : base(options) { }

    public DbSet<EmergencyAlert> Alerts => Set<EmergencyAlert>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<EmergencyAlert>(entity =>
        {
            entity.ToTable("Alerts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Type).IsRequired().HasConversion<string>();
            entity.Property(e => e.Status).IsRequired().HasConversion<string>();
            entity.Property(e => e.Description).HasMaxLength(500);
            
            entity.HasIndex(e => e.SocietyId);
            entity.HasIndex(e => new { e.SocietyId, e.Status }); // Crucial for fast active alert lookups
            entity.HasIndex(e => e.TriggeredById);
        });
    }
}