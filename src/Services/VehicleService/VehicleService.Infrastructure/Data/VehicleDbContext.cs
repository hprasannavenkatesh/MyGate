using VehicleService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace VehicleService.Infrastructure.Data;

public class VehicleDbContext : DbContext
{
    public VehicleDbContext(DbContextOptions<VehicleDbContext> options) : base(options) { }

    public DbSet<ParkingSlot> ParkingSlots => Set<ParkingSlot>();
    public DbSet<Vehicle> Vehicles => Set<Vehicle>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ParkingSlot>(entity =>
        {
            entity.ToTable("ParkingSlots");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SlotNumber).IsRequired().HasMaxLength(20);
            entity.Property(e => e.SlotType).IsRequired();

            // Indexes — merged from both duplicate blocks
            entity.HasIndex(e => new { e.SocietyId, e.SlotNumber }).IsUnique();
            entity.HasIndex(e => e.BlockId);
            entity.HasIndex(e => e.FlatId);
        });

        modelBuilder.Entity<Vehicle>(entity =>
        {
            entity.ToTable("Vehicles");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.VehicleNumber).IsRequired().HasMaxLength(20);
            entity.Property(e => e.VehicleType).IsRequired();

            entity.HasOne(e => e.ParkingSlot)
                  .WithOne(e => e.ParkedVehicle)
                 //.WithMany() //Assuming ParkingSlot doesn't have a List<Vehicle> property.
                  .HasForeignKey<Vehicle>(e => e.ParkingSlotId)
                  //.HasForeignKey(e => e.ParkingSlotId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(e => new { e.SocietyId, e.VehicleNumber });
            entity.HasIndex(e => e.FlatId);
            entity.HasIndex(e => e.OwnerId);
        });
    }
}