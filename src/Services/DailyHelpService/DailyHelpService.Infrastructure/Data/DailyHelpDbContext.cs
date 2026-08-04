using DailyHelpService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DailyHelpService.Infrastructure.Data;

public class DailyHelpDbContext : DbContext
{
    public DailyHelpDbContext(DbContextOptions<DailyHelpDbContext> options) : base(options) { }

    public DbSet<HelpType> HelpTypes => Set<HelpType>();
    public DbSet<DailyHelpStaff> Staff => Set<DailyHelpStaff>();
    public DbSet<DailyHelpAssignment> Assignments => Set<DailyHelpAssignment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<HelpType>(entity =>
        {
            entity.ToTable("HelpTypes");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(50);
            entity.HasIndex(e => new { e.SocietyId, e.Name }).IsUnique(); // No duplicate types per society
        });

        modelBuilder.Entity<DailyHelpStaff>(entity =>
        {
            entity.ToTable("Staff");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.MobileNumber).IsRequired().HasMaxLength(15);
            
            entity.HasOne(e => e.HelpType)
                  .WithMany(t => t.Staff)
                  .HasForeignKey(e => e.HelpTypeId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(e => e.SocietyId);
            entity.HasIndex(e => new { e.SocietyId, e.HelpTypeId });
        });

        modelBuilder.Entity<DailyHelpAssignment>(entity =>
        {
            entity.ToTable("Assignments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.WorkingDays).IsRequired().HasMaxLength(100);
            
            entity.HasOne(e => e.Staff)
                  .WithMany(s => s.Assignments)
                  .HasForeignKey(e => e.StaffId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(e => e.FlatId);
            entity.HasIndex(e => e.StaffId);
            entity.HasIndex(e => new { e.FlatId, e.IsActive });
        });
    }
}