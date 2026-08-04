using MediatR;

namespace DailyHelpService.Application.Features.HelpTypes.Commands.CreateHelpType;

public record CreateHelpTypeCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public string Name { get; init; } = string.Empty;
}