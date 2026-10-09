using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using HelpdeskService.Infrastructure.Persistence;
using Microsoft.OpenApi;
using HelpdeskService.Domain.Interfaces;
using HelpdeskService.Infrastructure.Repositories;
using HelpdeskService.Application.Features.Tickets.Queries;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();


// --- 1. THIS IS THE MISSING BLOCK ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
         policy.SetIsOriginAllowed(origin => true) // FIXED
              .AllowAnyMethod()    
              .AllowAnyHeader();   
    });
});

builder.Services.AddDbContext<HelpdeskDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("HelpdeskDb")));

builder.Services.AddScoped<ITicketRepository, TicketRepository>();
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(HelpdeskService.Application.Features.Tickets.Commands.RaiseTicketCommand).Assembly));

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
      var keyString = builder.Configuration["Jwt:Key"] 
            ?? throw new InvalidOperationException("JWT Key is missing from configuration.");
        var key = Encoding.UTF8.GetBytes(keyString);
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true, ValidateAudience = true, ValidateLifetime = true, ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"], ValidAudience = builder.Configuration["Jwt:Audience"],
          IssuerSigningKey = new SymmetricSecurityKey(key)
        //IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))

    };
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme { Name = "Authorization", Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT", In = ParameterLocation.Header });
    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement { [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>() });
});

var app = builder.Build();
app.UseSwagger(); app.UseSwaggerUI();
app.UseCors("AllowFlutter");
app.UseAuthentication(); app.UseAuthorization();
// ADD THIS BLOCK RIGHT BEFORE app.MapControllers();
app.Use(async (context, next) =>
{
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    var authHeader = context.Request.Headers["Authorization"].ToString();
    
    logger.LogInformation("=== HELPDESK REQUEST DEBUG ===");
    logger.LogInformation("Path: {Path}", context.Request.Path);
    logger.LogInformation("Has Auth Header: {HasAuth}", !string.IsNullOrEmpty(authHeader));
    if (!string.IsNullOrEmpty(authHeader))
    {
        logger.LogInformation("Token Prefix: {TokenPrefix}", authHeader.Substring(0, Math.Min(20, authHeader.Length))); // Log first 20 chars
    }
    logger.LogInformation("User Is Authenticated: {IsAuth}", context.User.Identity?.IsAuthenticated ?? false);
    logger.LogInformation("==============================");

    try
    {
        await next();
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Request failed");
        throw;
    }
});


app.MapControllers();
app.Run();