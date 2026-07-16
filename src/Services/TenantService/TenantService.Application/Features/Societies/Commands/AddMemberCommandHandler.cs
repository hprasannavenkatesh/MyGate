using MediatR;
using TenantService.Domain.Entities;
using TenantService.Domain.Interfaces;


namespace TenantService.Application.Features.Societies.Commands;

public class AddMemberCommandHandler : IRequestHandler<AddMemberCommand, Guid>
{
    private readonly ISocietyMemberRepository _repository;

    public AddMemberCommandHandler(ISocietyMemberRepository repository)
    {
        _repository = repository;
    }

    public async Task<Guid> Handle(AddMemberCommand request, CancellationToken cancellationToken)
    {
        // 1. Parse the string to our Enum
        if (!Enum.TryParse<MemberType>(request.MemberType, out var memberType))
        {
            throw new ArgumentException($"Invalid MemberType: {request.MemberType}");
        }

        // 2. Use our Domain Entity to create the record
        var member = new SocietyMember(
            request.SocietyId,
            request.UserId,
            request.FlatId,
            memberType,
            request.IsPrimary
        );

        // 3. Save to database
        var result = await _repository.AddAsync(member);

        return result.Id;
    }
}