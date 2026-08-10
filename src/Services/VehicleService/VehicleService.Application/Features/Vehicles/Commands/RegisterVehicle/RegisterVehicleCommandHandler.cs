using VehicleService.Domain.Enums;
using VehicleService.Domain.Interfaces;
using MediatR;

namespace VehicleService.Application.Features.Vehicles.Commands.RegisterVehicle;

public class RegisterVehicleCommandHandler : IRequestHandler<RegisterVehicleCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public RegisterVehicleCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Guid> Handle(RegisterVehicleCommand request, CancellationToken cancellationToken)
    {
        var isTaken = await _unitOfWork.Vehicles.IsVehicleNumberTakenAsync(request.SocietyId, request.VehicleNumber, cancellationToken);
        if (isTaken) throw new InvalidOperationException("A vehicle with this number is already registered in the society.");

        // THE NEW VALIDATION: Enforce Flat Vehicle Limits
        var currentCount = await _unitOfWork.Vehicles.CountActiveVehiclesByTypeAsync(
            request.SocietyId, request.FlatId, request.VehicleType, cancellationToken);

        if (request.VehicleType == VehicleType.FourWheeler && currentCount >= 1)
            throw new InvalidOperationException("This flat has reached the maximum limit of 1 Four-Wheeler.");

        if (request.VehicleType == VehicleType.TwoWheeler && currentCount >= 2)
            throw new InvalidOperationException("This flat has reached the maximum limit of 2 Two-Wheelers.");

        var vehicle = Domain.Entities.Vehicle.CreateResidentVehicle(
            request.SocietyId, request.OwnerId, request.FlatId, request.VehicleNumber, request.VehicleType, request.MakeModel);

        _unitOfWork.Vehicles.Add(vehicle);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return vehicle.Id;
    }
}