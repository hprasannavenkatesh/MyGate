using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using DailyHelpService.Infrastructure.Data;
using Microsoft.OpenApi;
using DailyHelpService.Domain.Interfaces;
using DailyHelpService.Infrastructure.Repositories;
using FluentValidation;


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
builder.Services.AddDbContext<DailyHelpDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- Repositories & UnitOfWork ---
builder.Services.AddScoped<IHelpTypeRepository, HelpTypeRepository>();
builder.Services.AddScoped<IDailyHelpStaffRepository, DailyHelpStaffRepository>();
builder.Services.AddScoped<IDailyHelpAssignmentRepository, DailyHelpAssignmentRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// --- MediatR & Validation ---
// --- MediatR & Validation ---
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(DailyHelpService.Application.Features.HelpTypes.Commands.CreateHelpType.CreateHelpTypeCommand).Assembly));
builder.Services.AddValidatorsFromAssembly(typeof(DailyHelpService.Application.Features.HelpTypes.Commands.CreateHelpType.CreateHelpTypeCommand).Assembly);
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
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Daily Help Service API", Version = "v1" });
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