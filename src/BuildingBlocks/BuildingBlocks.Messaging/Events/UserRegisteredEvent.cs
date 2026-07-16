namespace BuildingBlocks.Messaging.Events;

// This is the exact data the DJ broadcasts
public record UserRegisteredEvent(
    Guid UserId, 
    string MobileNumber, 
    string FullName, 
    DateTime RegisteredAt
);