using System.Text;                                                                                          
using BuildingBlocks.Messaging.Interfaces;
using IdentityService.Domain.Interfaces;
using IdentityService.Infrastructure.Persistence;
using IdentityService.Infrastructure.Repositories;
using IdentityService.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

// 1. Add Controllers 
builder.Services.AddControllers();

// Add this right under AddControllers()
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin() // Allow any port (like localhost:55415)
              .AllowAnyMethod() // Allow GET, POST, etc.
              .AllowAnyHeader(); // Allow JSON content
    });
});

// 2. Add MediatR (Tell it to scan the Application layer for Commands/Queries)
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(IdentityService.Application.Features.Auth.Commands.RegisterUserCommand).Assembly));

// 3. Add Database Context (Using a local SQL Server connection string)
builder.Services.AddDbContext<IdentityDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("IdentityDb")));


// 4. Wire up the Repository (When code asks for IUserRepository, give it UserRepository)
builder.Services.AddScoped<IUserRepository, UserRepository>();

// NEW: Wire up our new services
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();
builder.Services.AddSingleton<IEventBus, LocalEventBus>();
builder.Services.AddScoped<ITokenService, TokenService>();

// -------------------------------

// --- NEW: 5. Turn on the JWT Bouncer ---
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
        //IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
});
// ----------------------------------------

// --- NEW: 6. Tell Swagger to ask for a Token ---
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
    });
    /*c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });*/
    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>()
    });
});
// ----------------------------------------


// 5. Add Swagger for visual testing
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
// ----------------------------------------


var app = builder.Build();

// --- NEW: Turn on Authentication/Authorization middleware ---
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("AllowFlutter"); // ADD THIS!
app.UseAuthentication(); // MUST be before Authorization!
app.UseAuthorization();
// ------------------------------------

// 6. Turn on the Swagger UI ---
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
// ------------------------------------
// 7. Map Controllers (WE MISSED THIS TOO!)
app.MapControllers();

app.Run();