using DailyHelpService.Application.DTOs;
using MediatR;

namespace DailyHelpService.Application.Features.Assignments.Queries.GetMyAssignments;

public record GetMyAssignmentsQuery : IRequest<IReadOnlyList<DailyHelpAssignmentDto>>
{
    public Guid FlatId { get; init; }
}