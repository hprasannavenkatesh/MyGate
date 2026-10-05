// AmenityService/AmenityService.Application/Features/Amenities/Commands/DeleteAmenity/DeleteAmenityCommandHandler.cs

using AmenityService.Domain.Interfaces;
using MediatR;

namespace AmenityService.Application.Features.Amenities.Commands.DeleteAmenity;

public class DeleteAmenityCommandHandler : IRequestHandler<DeleteAmenityCommand, Unit>
{
    private readonly IUnitOfWork _unitOfWork;

    public DeleteAmenityCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Unit> Handle(DeleteAmenityCommand request, CancellationToken cancellationToken)
    {
        // 1. Get the amenity
        var amenity = await _unitOfWork.Amenities.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new KeyNotFoundException($"Amenity with ID {request.Id} not found.");

        // 2. Security: Ensure amenity belongs to the specified society
        if (amenity.SocietyId != request.SocietyId)
            throw new UnauthorizedAccessException("You do not have access to this amenity.");

        // 3. Soft delete — deactivate instead of hard delete (preserves booking history)
        amenity.Deactivate();

        // 4. Persist
        _unitOfWork.Amenities.Update(amenity);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}