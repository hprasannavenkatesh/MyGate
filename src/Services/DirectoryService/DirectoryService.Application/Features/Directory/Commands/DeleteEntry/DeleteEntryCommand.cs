using MediatR;

namespace DirectoryService.Application.Features.Directory.Commands.DeleteEntry;

public record DeleteEntryCommand : IRequest<Unit>
{
    public Guid Id { get; init; }
    public Guid SocietyId { get; init; }
}