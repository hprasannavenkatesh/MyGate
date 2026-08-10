using FluentValidation;

namespace VehicleService.Application.Features.ParkingSlots.Commands.CreateSlot;

public class CreateSlotCommandValidator : AbstractValidator<CreateSlotCommand>
{
    public CreateSlotCommandValidator()
    {
        RuleFor(x => x.SocietyId).NotEmpty();
        RuleFor(x => x.SlotNumber).NotEmpty().MaximumLength(20);
        RuleFor(x => x.SlotType).IsInEnum();
        
    }
}