using MediatR;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;

namespace TenantService.Application.Features.Societies.Commands;

public class CreateSocietyCommandHandler : IRequestHandler<CreateSocietyCommand, Guid>
{
    private readonly ISocietyRepository _repository;
    public CreateSocietyCommandHandler(ISocietyRepository repository) => _repository = repository;

    public async Task<Guid> Handle(CreateSocietyCommand request, CancellationToken cancellationToken)
    {
        var society = new Society(request.Name, request.Code, request.Address, request.City);
        return (await _repository.AddAsync(society)).Id;
    }
}