using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VisitorService.Domain.Interfaces;
using VisitorService.Infrastructure.Persistence;
using VisitorService.Infrastructure.Repositories;
using VisitorService.Infrastructure.Services;
using Microsoft.OpenApi;
using System.Text.Json.Serialization; 

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddCors(options =>
{
   /* options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });*/
     options.AddPolicy("AllowFlutter", policy =>
    {
        policy.SetIsOriginAllowed(origin => true) // THE MAGIC LINE
              .AllowAnyMethod()    
              .AllowAnyHeader();   
    });
});

// 1. Database
builder.Services.AddDbContext<VisitorDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("VisitorDb")));

// 2. Repositories (We will create the interface/implementation next)
builder.Services.AddScoped<IPreApprovedVisitorRepository, PreApprovedVisitorRepository>();
builder.Services.AddScoped<IVisitorLogRepository, VisitorLogRepository>();
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();

// 3. MediatR
//builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(VisitorService.Application.Features.Visitors.Commands.PreApproveVisitorCommand).Assembly));
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(VisitorService.Application.Features.Visitors.VisitorsServiceMarker).Assembly));

// 4. JWT Bouncer (Copied from Tenant Service)
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

// 5. Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme."
    });

   /* c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new List<string>()
        }
    });*/
     c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>()
    });
});

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // This converts Enums (1, 2) to Strings ("Entered", "Exited")
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("AllowFlutter");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();