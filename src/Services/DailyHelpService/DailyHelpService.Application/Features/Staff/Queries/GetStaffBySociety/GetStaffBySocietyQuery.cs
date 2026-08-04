using DailyHelpService.Application.DTOs;
using MediatR;

namespace DailyHelpService.Application.Features.Staff.Queries.GetStaffBySociety;

public record GetStaffBySocietyQuery : IRequest<IReadOnlyList<DailyHelpStaffDto>>
{
    public Guid SocietyId { get; init; }
    public Guid? HelpTypeId { get; init; }
}