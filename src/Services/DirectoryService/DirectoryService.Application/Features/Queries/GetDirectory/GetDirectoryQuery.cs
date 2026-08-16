using DirectoryService.Application.DTOs;
using MediatR;

namespace DirectoryService.Application.Features.Directory.Queries.GetDirectory;

public record GetDirectoryQuery : IRequest<IReadOnlyList<DirectoryEntryDto>>
{
    public Guid SocietyId { get; init; }
    public string? Category { get; init; }
    public string? Search { get; init; }
}