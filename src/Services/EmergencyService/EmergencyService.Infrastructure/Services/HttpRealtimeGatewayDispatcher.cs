using System.Text.Json;
using EmergencyService.Domain.Interfaces;
using Microsoft.Extensions.Configuration;

namespace EmergencyService.Infrastructure.Services;

public class HttpRealtimeGatewayDispatcher : IRealtimeGatewayDispatcher
{
    private readonly HttpClient _httpClient;

    public HttpRealtimeGatewayDispatcher(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;

        //var gatewayUrl = configuration.GetValue<string>("ServiceUrls:RealtimeGateway");
    var gatewayUrl = configuration["ServiceUrls:RealtimeGateway"];
    if (!string.IsNullOrEmpty(gatewayUrl))
        {
            _httpClient.BaseAddress = new Uri(gatewayUrl);
        }
        else
        {
            throw new InvalidOperationException("ServiceUrls:RealtimeGateway URL is not configured in appsettings.json.");
        }
      
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