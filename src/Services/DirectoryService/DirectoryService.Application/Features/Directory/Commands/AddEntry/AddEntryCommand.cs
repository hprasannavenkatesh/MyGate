using MediatR;

namespace DirectoryService.Application.Features.Directory.Commands.AddEntry;

public record AddEntryCommand : IRequest<Guid>
{
    public Guid SocietyId { get; init; }
    public string Category { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string ContactNumber { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Notes { get; init; }
}