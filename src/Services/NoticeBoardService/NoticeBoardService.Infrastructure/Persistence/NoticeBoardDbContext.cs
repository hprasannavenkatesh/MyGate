using Microsoft.EntityFrameworkCore;
using NoticeBoardService.Domain.Entities;

namespace NoticeBoardService.Infrastructure.Persistence;

public class NoticeBoardDbContext : DbContext
{
    public NoticeBoardDbContext(DbContextOptions<NoticeBoardDbContext> options) : base(options) { }

    public DbSet<Notice> Notices => Set<Notice>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Notice>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).IsRequired();
            entity.HasIndex(e => e.SocietyId); // Important for fast querying
        });
    }
}