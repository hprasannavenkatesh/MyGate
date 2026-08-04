using AmenityService.Domain.Enums;

namespace AmenityService.Domain.Entities;

public class AmenityBooking : BaseEntity
{
    public Guid AmenityId { get; private set; }
    public Guid SocietyId { get; private set; }
    public Guid UserId { get; private set; }
    public string FlatNumber { get; private set; } = string.Empty;
    
    // Booking Time
    public DateOnly BookingDate { get; private set; }
    public TimeOnly StartTime { get; private set; }
    public TimeOnly EndTime { get; private set; }
    
    // Status
    public BookingStatus Status { get; private set; } = BookingStatus.Pending;
    public string? Notes { get; private set; }
    
    // Approval Tracking
    public Guid? ApprovedBy { get; private set; }
    public DateTimeOffset? ApprovedAt { get; private set; }
    public string? RejectionReason { get; private set; }
    
    // Navigation
    public virtual Amenity Amenity { get; private set; } = null!;

    private AmenityBooking() { } // EF Core

    public static AmenityBooking Create(
        Guid amenityId,
        Guid societyId,
        Guid userId,
        string flatNumber,
        DateOnly bookingDate,
        TimeOnly startTime,
        TimeOnly endTime,
        string? notes)
    {
        if (string.IsNullOrWhiteSpace(flatNumber))
            throw new ArgumentException("Flat number is required.", nameof(flatNumber));

        if (startTime >= endTime)
            throw new ArgumentException("Start time must be before end time.", nameof(startTime));

        return new AmenityBooking
        {
            AmenityId = amenityId,
            SocietyId = societyId,
            UserId = userId,
            FlatNumber = flatNumber.Trim(),
            BookingDate = bookingDate,
            StartTime = startTime,
            EndTime = endTime,
            Notes = notes?.Trim()
        };
    }

    public void Approve(Guid approvedBy)
    {
        if (Status != BookingStatus.Pending)
            throw new InvalidOperationException($"Cannot approve booking in {Status} status.");

        Status = BookingStatus.Approved;
        ApprovedBy = approvedBy;
        ApprovedAt = DateTimeOffset.UtcNow;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Reject(Guid rejectedBy, string reason)
    {
        if (Status != BookingStatus.Pending)
            throw new InvalidOperationException($"Cannot reject booking in {Status} status.");

        Status = BookingStatus.Rejected;
        ApprovedBy = rejectedBy;
        ApprovedAt = DateTimeOffset.UtcNow;
        RejectionReason = reason?.Trim();
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Cancel()
    {
        if (Status is not (BookingStatus.Pending or BookingStatus.Approved))
            throw new InvalidOperationException($"Cannot cancel booking in {Status} status.");

        Status = BookingStatus.Cancelled;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkCompleted()
    {
        if (Status != BookingStatus.Approved)
            throw new InvalidOperationException($"Cannot complete booking in {Status} status.");

        Status = BookingStatus.Completed;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public bool IsTimeOverlapping(TimeOnly otherStart, TimeOnly otherEnd)
    {
        return StartTime < otherEnd && EndTime > otherStart;
    }
}