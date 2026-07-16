using MediatR;

namespace TenantService.Application.Features.Societies.Commands;

public class CreateFlatCommand : IRequest<Guid>
{
    public Guid BlockId { get; set; }
    public string FlatNumber { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
}