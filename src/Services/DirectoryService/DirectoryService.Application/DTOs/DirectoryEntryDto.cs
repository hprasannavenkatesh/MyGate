namespace DirectoryService.Application.DTOs;

public record DirectoryEntryDto(
    Guid Id,
    string Category,
    string Name,
    string ContactNumber,
    string? Email,
    string? Address,
    string? Notes);