using MediatR;
using HelpdeskService.Domain.Entities;
using HelpdeskService.Domain.Interfaces;
using System.Security.Claims;


namespace HelpdeskService.Application.Features.Tickets.Commands;

public class AddCommentCommandHandler : IRequestHandler<AddCommentCommand, Unit>
{
    private readonly ITicketRepository _repository;
     public AddCommentCommandHandler(ITicketRepository repository) => _repository = repository;


    public async Task<Unit> Handle(AddCommentCommand request, CancellationToken cancellationToken)
    {
        // Now we just use the ID passed safely from the controller
        var comment = new TicketComment(
            request.TicketId, 
            request.UserId, 
            request.CommentText, 
            request.IsAdminComment
        );
        
        await _repository.AddCommentAsync(comment);
        return Unit.Value;
    }
}