using AmenityService.Application.DTOs;
using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Bookings.Queries.GetPendingBookings;

public class GetPendingBookingsQueryHandler : IRequestHandler<GetPendingBookingsQuery, IReadOnlyList<AmenityBookingDto>>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetPendingBookingsQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<IReadOnlyList<AmenityBookingDto>> Handle(GetPendingBookingsQuery request, CancellationToken cancellationToken)
    {
        var bookings = await _unitOfWork.AmenityBookings.GetPendingBySocietyAsync(
            request.SocietyId, cancellationToken);

        return bookings.Select(MapToDto).ToList();
    }

    private static AmenityBookingDto MapToDto(Domain.Entities.AmenityBooking b) => new(
        b.Id,
        b.AmenityId,
        b.Amenity?.Name ?? string.Empty,
        b.SocietyId,
        b.UserId,
        b.FlatNumber,
        b.BookingDate,
        b.StartTime.ToString("HH:mm"),
        b.EndTime.ToString("HH:mm"),
        b.Status,
        b.Notes,
        b.ApprovedBy,
        b.ApprovedAt,
        b.RejectionReason,
        b.CreatedAt);
}