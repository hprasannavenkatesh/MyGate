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
        policy.AllowAnyOrigin()    
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
app.MapControllers();
app.Run();