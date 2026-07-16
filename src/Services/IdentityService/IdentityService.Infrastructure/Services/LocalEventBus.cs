using System.Text.Json;
using BuildingBlocks.Messaging.Events;
using BuildingBlocks.Messaging.Interfaces;

namespace IdentityService.Infrastructure.Services;

public class LocalEventBus : IEventBus
{
    public Task PublishAsync<TEvent>(TEvent eventData, string topicName) where TEvent : class
    {
        // In the real world, this sends data to Azure. 
        // For local testing, we just print it to the terminal!
        var json = JsonSerializer.Serialize(eventData, new JsonSerializerOptions { WriteIndented = true });
        
        Console.WriteLine("=========================================");
        Console.WriteLine($"🎤 DJ BROADCASTING ON TOPIC: [{topicName}]");
        Console.WriteLine("=========================================");
        Console.WriteLine(json);
        Console.WriteLine("=========================================");

        return Task.CompletedTask;
    }
}