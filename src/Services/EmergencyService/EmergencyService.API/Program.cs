using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using EmergencyService.Infrastructure.Data;
using Microsoft.OpenApi;
using EmergencyService.Domain.Interfaces;
using EmergencyService.Infrastructure.Repositories;
using EmergencyService.Infrastructure.Services;
using FluentValidation;
 using System.Text.Json;


var builder = WebApplication.CreateBuilder(args);



builder.Services.AddControllers();

// --- CORS ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        //policy.AllowAnyOrigin()   
         policy.SetIsOriginAllowed(origin => true) // The magic line! 
              .AllowAnyMethod()    
              .AllowAnyHeader();   
    });
});

// --- Database ---
builder.Services.AddDbContext<EmergencyDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- Repositories & UnitOfWork ---
builder.Services.AddScoped<IEmergencyAlertRepository, EmergencyAlertRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<IRealtimeGatewayDispatcher, HttpRealtimeGatewayDispatcher>();

// --- MediatR & Validation ---
// --- MediatR & Validation ---
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(EmergencyService.Application.Features.Alerts.Commands.TriggerPanic.TriggerPanicCommand).Assembly));
builder.Services.AddValidatorsFromAssembly(typeof(EmergencyService.Application.Features.Alerts.Commands.TriggerPanic.TriggerPanicCommand).Assembly);

builder.Services.AddHttpClient<IRealtimeGatewayDispatcher, HttpRealtimeGatewayDispatcher>();

// --- Authentication ---
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
        ValidateIssuer = true,  
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

// --- Swagger ---
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Vehicle Service API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme 
    { 
        Name = "Authorization", 
        Type = SecuritySchemeType.Http, 
        Scheme = "bearer", 
        BearerFormat = "JWT", 
        In = ParameterLocation.Header 
    });
    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement 
    { 
        [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>() 
    });
});


builder.Services.AddHttpClient<IRealtimeGatewayDispatcher, HttpRealtimeGatewayDispatcher>();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("AllowFlutter");
app.UseAuthentication();
app.UseAuthorization();

// ADD THIS BLOCK RIGHT HERE:
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (InvalidOperationException ex)
    {
        context.Response.StatusCode = 400;
        await context.Response.WriteAsJsonAsync(new { message = ex.Message });
    }
    catch (Exception ex)
    {
        Console.WriteLine(ex.Message.ToString());
        context.Response.StatusCode = 500;
        await context.Response.WriteAsJsonAsync(new { message = "An unexpected error occurred." });
    }
});



app.MapControllers();

app.Run();

