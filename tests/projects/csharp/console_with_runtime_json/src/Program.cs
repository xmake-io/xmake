using System.Text.Json;

var runtimeFile = Path.Combine(AppContext.BaseDirectory, "runtime.json");
if (!File.Exists(runtimeFile))
{
    Console.WriteLine("runtime.json missing");
    return;
}

var json = File.ReadAllText(runtimeFile);
using var doc = JsonDocument.Parse(json);
var runtime = doc.RootElement.TryGetProperty("runtime", out var value)
    ? value.GetString()
    : "unknown";

Console.WriteLine($"runtime={runtime}");

