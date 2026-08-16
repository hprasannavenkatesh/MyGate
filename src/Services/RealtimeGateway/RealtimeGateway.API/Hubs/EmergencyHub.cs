using Microsoft.AspNetCore.SignalR;

namespace RealtimeGateway.API.Hubs;

// Residents and Guards connect here for Panic Buttons and Alerts
public class EmergencyHub : Hub
{
    // Called by Flutter when the app opens to join their specific society channel
    public async Task JoinSocietyGroup(string societyId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"society_{societyId}");
    }

    // Called by Flutter when app closes to clean up memory
    public async Task LeaveSocietyGroup(string societyId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"society_{societyId}");
    }
}