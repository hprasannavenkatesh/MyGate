using System.Text.Json;
using EmergencyService.Domain.Interfaces;

namespace EmergencyService.Infrastructure.Services;

public class HttpRealtimeGatewayDispatcher : IRealtimeGatewayDispatcher
{
    private readonly HttpClient _httpClient;

    public HttpRealtimeGatewayDispatcher(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri("http://localhost:5114"); // Gateway URL
    }

    public async Task BroadcastEmergencyAlertAsync(Guid societyId, object alertPayload, CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            methodName = "ReceiveEmergencyAlert",
            groupName = $"society_{societyId}",
            args = new[] { alertPayload }
        };

        var jsonContent = new StringContent(
            JsonSerializer.Serialize(payload),
            System.Text.Encoding.UTF8,
            "application/json");

        // Call the Gateway API (we will add this endpoint to the Gateway next)
        var response = await _httpClient.PostAsync("/api/gateway/broadcast", jsonContent, cancellationToken);
        
        // We don't throw if gateway is down, safety first for emergencies
        response.EnsureSuccessStatusCode(); 
    }
}