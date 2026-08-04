using HelpdeskService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace HelpdeskService.Infrastructure.Persistence;

public class HelpdeskDbContext : DbContext
{
    public HelpdeskDbContext(DbContextOptions<HelpdeskDbContext> options) : base(options)
    {
    }

    public DbSet<Ticket> Tickets => Set<Ticket>();
    public DbSet<TicketComment> TicketComments => Set<TicketComment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Ticket>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            // NEW: Tell EF Core to load comments automatically when fetching a ticket
            entity.HasMany(e => e.Comments).WithOne().HasForeignKey(c => c.TicketId);
        });

        modelBuilder.Entity<TicketComment>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.CommentText).IsRequired();
        });
    }
}