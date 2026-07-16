using BuildingBlocks.Messaging.Events;

namespace BuildingBlocks.Messaging.Interfaces;

public interface IEventBus
{
    // The DJ uses this to broadcast
    Task PublishAsync<TEvent>(TEvent eventData, string topicName) where TEvent : class;
}