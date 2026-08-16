using Microsoft.AspNetCore.SignalR;

namespace RealtimeGateway.API.Hubs;

// Residents connect here for Group Chats
public class ChatHub : Hub
{
    public async Task JoinChatGroup(string groupId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"chat_{groupId}");
    }

    public async Task LeaveChatGroup(string groupId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"chat_{groupId}");
    }
}