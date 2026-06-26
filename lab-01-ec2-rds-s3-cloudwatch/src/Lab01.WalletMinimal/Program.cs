using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Database
var dbHost = Environment.GetEnvironmentVariable("DB_HOST") ?? "docker-local";
var dbPort = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
var dbName = Environment.GetEnvironmentVariable("DB_NAME") ?? "local_csnp";
var dbUser = Environment.GetEnvironmentVariable("DB_USER") ?? "local";
var dbPass = Environment.GetEnvironmentVariable("DB_PASSWORD") ?? "Local+PASSWORD";

builder.Services.AddDbContext<WalletDb>(opt =>
    opt.UseNpgsql($"Host={dbHost};Port={dbPort};Database={dbName};Username={dbUser};Password={dbPass}"));

// S3 - dùng IAM Role, không cần AccessKey
builder.Services.AddAWSService<IAmazonS3>();

var app = builder.Build();

// Auto migrate
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<WalletDb>();
    db.Database.EnsureCreated();
}

// Health check
app.MapGet("/health", () => Results.Ok(new { status = "ok", time = DateTime.UtcNow }));

// GET all wallets
app.MapGet("/wallets", async (WalletDb db) =>
    await db.Wallets.ToListAsync());

// POST create wallet
app.MapPost("/wallets", async (WalletDb db, Wallet wallet) =>
{
    wallet.Id = Guid.NewGuid();
    wallet.CreatedAt = DateTime.UtcNow;
    db.Wallets.Add(wallet);
    await db.SaveChangesAsync();
    return Results.Created($"/wallets/{wallet.Id}", wallet);
});

// POST upload file lên S3
app.MapPost("/upload", async (HttpRequest req, IAmazonS3 s3) =>
{
    var bucket = Environment.GetEnvironmentVariable("S3_BUCKET") ?? "csnp-wallet-dev";
    var key = $"uploads/{Guid.NewGuid()}.txt";
    await s3.PutObjectAsync(new PutObjectRequest
    {
        BucketName = bucket,
        Key = key,
        ContentBody = "Hello from CSNP Wallet API on AWS!"
    });
    return Results.Ok(new { bucket, key });
});

app.Run();

// Models
public class Wallet
{
    public Guid Id { get; set; }
    public string OwnerId { get; set; } = "";
    public decimal Balance { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class WalletDb : DbContext
{
    public WalletDb(DbContextOptions<WalletDb> options) : base(options) { }
    public DbSet<Wallet> Wallets => Set<Wallet>();
}