# ==============================================================================
# SCRIPT: Start All MyGate .NET Microservices in VS Code Terminals
# USAGE: Run from the root directory (C:\MyGateApp)
# REQUIREMENT: VS Code must be your current IDE
# ==============================================================================

# Define the root path for all services
 $servicesRoot = "C:\MyGateApp\src\Services"

# Define all services and their specific project paths relative to the service root
 $services = @(
    @{ Name = "IdentityService (5103)"; Path = "$servicesRoot\IdentityService\IdentityService.API" },
    @{ Name = "TenantService (5104)"; Path = "$servicesRoot\TenantService\TenantService.API" },
    @{ Name = "VisitorService (5105)"; Path = "$servicesRoot\VisitorService\VisitorService.API" },
    @{ Name = "BillingService (5107)"; Path = "$servicesRoot\BillingService\BillingService.API" },
    @{ Name = "HelpdeskService (5108)"; Path = "$servicesRoot\HelpdeskService\HelpdeskService.API" },
    @{ Name = "NoticeBoardService (5109)"; Path = "$servicesRoot\NoticeBoardService\NoticeBoardService.API" },
    @{ Name = "AmenityService (5110)"; Path = "$servicesRoot\AmenityService\AmenityService.API" },
    @{ Name = "DailyHelpService (5111)"; Path = "$servicesRoot\DailyHelpService\DailyHelpService.API" },
    @{ Name = "VehicleService (5112)"; Path = "$servicesRoot\VehicleService\VehicleService.API" },
    @{ Name = "DirectoryService (5113)"; Path = "$servicesRoot\DirectoryService\DirectoryService.API" },
    @{ Name = "EmergencyService (5114)"; Path =  "$servicesRoot\EmergencyService\EmergencyService.API" },
    @{ Name = "RealtimeGateway (5116)"; Path = "$servicesRoot\RealtimeGateway\RealtimeGateway.API" } # Include if you have this folder
)

Write-Host "🚀 Starting MyGate Microservices in VS Code Terminals..." -ForegroundColor Cyan

Foreach ($service in $services) {
    # Check if the project directory exists before trying to run it
    if (Test-Path $service.Path) {
        Write-Host "Starting $($service.Name)..." -ForegroundColor Yellow
        
        # Send command to VS Code to create a new named terminal and run the service
        # --cwd ensures `dotnet run` happens inside the correct .csproj folder
        code --cmd "workbench.action.terminal.newWithProfile" `
             --profile-name "$($service.Name)" `
             --cmd "workbench.action.terminal.sendSequence" `
             --text "cd '$($service.Path)' && dotnet run"
    }
    else {
        Write-Host "⚠️ SKIPPED: Directory not found for $($service.Name) at $($service.Path)" -ForegroundColor Red
    }
}

Write-Host "✅ All service terminals launched! Check your VS Code Terminal Panel." -ForegroundColor Green