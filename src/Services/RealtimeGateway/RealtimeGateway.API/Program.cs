using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using RealtimeGateway.API.Hubs;

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

app.Run();