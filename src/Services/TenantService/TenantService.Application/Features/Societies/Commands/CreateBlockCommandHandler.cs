using MediatR;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;

namespace TenantService.Application.Features.Societies.Commands;

public class CreateBlockCommandHandler : IRequestHandler<CreateBlockCommand, Guid>
{
    private readonly IFlatRepository _repository;
    public CreateBlockCommandHandler(IFlatRepository repository) => _repository = repository;

    public async Task<Guid> Handle(CreateBlockCommand request, CancellationToken cancellationToken)
    {
        var block = new Block(request.SocietyId, request.Name);
        return (await _repository.AddBlockAsync(block)).Id;
    }
}