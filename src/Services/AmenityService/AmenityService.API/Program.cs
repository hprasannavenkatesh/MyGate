using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using AmenityService.Infrastructure.Data;
using Microsoft.OpenApi;
using AmenityService.Domain.Interfaces;
using AmenityService.Infrastructure.Repositories;
using AmenityService.Application.Features.Amenities.Commands.CreateAmenity;
using AmenityService.Application.Common.Behaviors;
using FluentValidation;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

// --- CORS ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        // policy.WithOrigins("http://localhost:5110", "http://localhost:3000", "http://localhost:54251") // Added 5110 for Swagger
        policy.AllowAnyOrigin()   
         //policy.SetIsOriginAllowed(origin => true) // The magic line! 
              .AllowAnyMethod()    
              .AllowAnyHeader();   
    });
});

// --- Database ---
builder.Services.AddDbContext<AmenityDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- Repositories & UnitOfWork ---
builder.Services.AddScoped<IAmenityRepository, AmenityRepository>();
builder.Services.AddScoped<IAmenityBookingRepository, AmenityBookingRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// --- MediatR & Validation ---
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(CreateAmenityCommand).Assembly));
builder.Services.AddValidatorsFromAssembly(typeof(CreateAmenityCommand).Assembly);
// Note: If you want FluentValidation to auto-run, you need to add the behavior:
// builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));

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
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Amenity Service API", Version = "v1" });
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



var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("AllowFlutter");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();