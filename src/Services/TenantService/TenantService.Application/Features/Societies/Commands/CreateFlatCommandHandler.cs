using MediatR;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;

namespace TenantService.Application.Features.Societies.Commands;

public class CreateFlatCommandHandler : IRequestHandler<CreateFlatCommand, Guid>
{
    private readonly IFlatRepository _repository;
    public CreateFlatCommandHandler(IFlatRepository repository) => _repository = repository;

    public async Task<Guid> Handle(CreateFlatCommand request, CancellationToken cancellationToken)
    {
        var flat = new Flat(request.BlockId, request.FlatNumber, request.Type);
        return (await _repository.AddFlatAsync(flat)).Id;
    }
}