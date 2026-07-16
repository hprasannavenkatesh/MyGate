using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using NotificationService.Infrastructure.Persistence;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddDbContext<NotificationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("NotificationDb")));
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(NotificationService.Application.Features.Notifications.NotificationServiceMarker).Assembly));

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
    //c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme { Name = "Authorization", Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey, Scheme = "Bearer", BearerFormat = "JWT", In = Microsoft.OpenApi.Models.ParameterLocation.Header });
    //c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement { { new Microsoft.OpenApi.Models.OpenApiSecurityScheme { Reference = new Microsoft.OpenApi.Models.OpenApiReference { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "Bearer" } }, Array.Empty<string>() } });
     c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
    });
      c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>()
    });
});

var app = builder.Build();
app.UseSwagger(); app.UseSwaggerUI();
app.UseAuthentication(); app.UseAuthorization();
app.MapControllers();
app.Run();