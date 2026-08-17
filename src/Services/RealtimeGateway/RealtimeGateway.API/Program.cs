/*using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.ResponseCaching;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.SignalR;
using System.Text.Json;
*/
global using RealtimeGateway.API.Hubs;
global using Microsoft.AspNetCore.SignalR;
global using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// 1. Add SignalR to the services
builder.Services.AddSignalR();

// 2. Add CORS (CRITICAL FOR FLUTTER WEB)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.SetIsOriginAllowed(origin => true) // Our silver bullet for Flutter Web
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); // REQUIRED FOR SIGNALR WEBSOCKETS!
    });
});

builder.Services.AddControllers();

var app = builder.Build();

// 3. Use CORS BEFORE SignalR
app.UseCors("AllowFlutter");

app.MapControllers();

// 4. Map the Hubs to specific endpoints
// Flutter will connect to these URLs
app.MapHub<EmergencyHub>("/hubs/emergency");
app.MapHub<ChatHub>("/hubs/chat");

// --- ADD THIS BLOCK ---
app.MapPost("/api/gateway/broadcast", async (HttpContext context, IHubContext<EmergencyHub> hubContext) =>
{
    using var reader = new StreamReader(context.Request.Body);
    var body = await reader.ReadToEndAsync();
    var payload = JsonSerializer.Deserialize<GatewayBroadcastRequest>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

    if (payload != null && !string.IsNullOrEmpty(payload.MethodName) && !string.IsNullOrEmpty(payload.GroupName))
    {
        await hubContext.Clients.Group(payload.GroupName).SendAsync(payload.MethodName, payload.Args);
    }

    return Results.Ok();
});

app.Run();

record GatewayBroadcastRequest(string MethodName, string GroupName, object[] Args);