var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "hello web xmake!");
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();

