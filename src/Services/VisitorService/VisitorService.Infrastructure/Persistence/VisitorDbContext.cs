using VisitorService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace VisitorService.Infrastructure.Persistence;

public class VisitorDbContext : DbContext
{
    public VisitorDbContext(DbContextOptions<VisitorDbContext> options) : base(options)
    {
    }

    public DbSet<PreApprovedVisitor> PreApprovedVisitors => Set<PreApprovedVisitor>();
    public DbSet<VisitorLog> VisitorLogs => Set<VisitorLog>();
}