using DailyHelpService.Application.DTOs;
using MediatR;

namespace DailyHelpService.Application.Features.HelpTypes.Queries.GetHelpTypesBySociety;

public record GetHelpTypesBySocietyQuery : IRequest<IReadOnlyList<HelpTypeDto>>
{
    public Guid SocietyId { get; init; }
}