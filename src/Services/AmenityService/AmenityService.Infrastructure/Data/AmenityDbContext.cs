using AmenityService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AmenityService.Infrastructure.Data;

public class AmenityDbContext : DbContext
{
    public AmenityDbContext(DbContextOptions<AmenityDbContext> options) : base(options)
    {
    }

    public DbSet<Amenity> Amenities => Set<Amenity>();
    public DbSet<AmenityBooking> AmenityBookings => Set<AmenityBooking>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        ConfigureAmenityEntity(modelBuilder);
        ConfigureAmenityBookingEntity(modelBuilder);
    }

    private static void ConfigureAmenityEntity(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.ToTable("Amenities");

            entity.HasKey(e => e.Id);

            entity.Property(e => e.SocietyId)
                .IsRequired();

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.Description)
                .HasMaxLength(500);

            entity.Property(e => e.Location)
                .HasMaxLength(200);

            entity.Property(e => e.SlotDurationMinutes)
                .IsRequired();

            entity.Property(e => e.MaxBookingsPerDayPerUser)
                .IsRequired()
                .HasDefaultValue(1);

            entity.Property(e => e.AdvanceBookingDaysAllowed)
                .IsRequired()
                .HasDefaultValue(7);

            entity.Property(e => e.OperatingHoursStart)
                .IsRequired();

            entity.Property(e => e.OperatingHoursEnd)
                .IsRequired();

            entity.HasIndex(e => e.SocietyId);
            entity.HasIndex(e => new { e.SocietyId, e.IsActive });
        });
    }

    private static void ConfigureAmenityBookingEntity(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AmenityBooking>(entity =>
        {
            entity.ToTable("AmenityBookings");

            entity.HasKey(e => e.Id);

            entity.Property(e => e.AmenityId)
                .IsRequired();

            entity.Property(e => e.SocietyId)
                .IsRequired();

            entity.Property(e => e.UserId)
                .IsRequired();

            entity.Property(e => e.FlatNumber)
                .IsRequired()
                .HasMaxLength(20);

            entity.Property(e => e.BookingDate)
                .IsRequired();

            entity.Property(e => e.StartTime)
                .IsRequired();

            entity.Property(e => e.EndTime)
                .IsRequired();

            entity.Property(e => e.Status)
                .IsRequired()
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.Notes)
                .HasMaxLength(500);

            entity.Property(e => e.RejectionReason)
                .HasMaxLength(300);

            // Relationships
            entity.HasOne(e => e.Amenity)
                .WithMany(a => a.Bookings)
                .HasForeignKey(e => e.AmenityId)
                .OnDelete(DeleteBehavior.Restrict);

            // Indexes for query performance
            entity.HasIndex(e => e.AmenityId);
            entity.HasIndex(e => e.SocietyId);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => new { e.AmenityId, e.BookingDate });
            entity.HasIndex(e => new { e.UserId, e.SocietyId });
            entity.HasIndex(e => new { e.SocietyId, e.Status });
            entity.HasIndex(e => new { e.UserId, e.AmenityId, e.BookingDate });
        });
    }
}