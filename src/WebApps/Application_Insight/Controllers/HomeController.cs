using System.Diagnostics;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Mvc;
using Application_Insight.Models;
using Azure.Storage.Blobs;
using Microsoft.Azure.Cosmos;

namespace Application_Insight.Controllers;

class Product
{
    public string Name
    {
        get;
        set;
    }
}

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly IConfiguration _config;
    private readonly TelemetryClient _telemetry;

    public HomeController(ILogger<HomeController> logger, IConfiguration config, TelemetryClient telemetry)
    {
        _logger = logger;
        _config = config;
        _telemetry = telemetry;
    }

    public IActionResult Index()
    {
        return View();
    }

    public IActionResult Privacy()
    {
        var storageAccountConnectionString = _config["ConnectionStrings:StorageAccount"];
        var storageAccountContainerName = _config["Settings:StorageAccountContainerName"];

        var cosmosDBConnectionsString = _config["ConnectionStrings:CosmosDB"];
        var cosmosDBDatabaseName = _config["Settings:CosmosDBDatabaseName"];
        var cosmosDBContainerName = _config["Settings:CosmosDBContainerName"];

        var containerClient = new BlobContainerClient(storageAccountConnectionString, storageAccountContainerName);

        var data = containerClient.GetBlobs();

        var result = string.Join(", ", data.Select(item => item.Name));

        ViewBag.data = result;

        var client = new CosmosClient(cosmosDBConnectionsString);
        var db = client.GetDatabase(cosmosDBDatabaseName);
        var container = db.GetContainer(cosmosDBContainerName);

        var queryText = "SELECT * FROM c";
        var query = new QueryDefinition(queryText);
        _telemetry.TrackTrace("CosmosDB SQL query executed", SeverityLevel.Information, new Dictionary<string, string>
        {
            ["db.system"] = "cosmosdb",
            ["db.name"] = cosmosDBDatabaseName ?? string.Empty,
            ["db.container"] = cosmosDBContainerName ?? string.Empty,
            ["db.statement"] = query.QueryText
        });

        FeedIterator<Product> iterator = container.GetItemQueryIterator<Product>(query);

        var cosmosResult = "";
        // Iterate over results
        while (iterator.HasMoreResults)
        {
            FeedResponse<Product> batch = iterator.ReadNextAsync().GetAwaiter().GetResult();
            _telemetry.TrackEvent("CosmosDB query page", new Dictionary<string, string>
            {
                ["db.system"] = "cosmosdb",
                ["db.name"] = cosmosDBDatabaseName ?? string.Empty,
                ["db.container"] = cosmosDBContainerName ?? string.Empty
            }, new Dictionary<string, double>
            {
                ["db.cosmosdb.request_charge"] = batch.RequestCharge
            });

            foreach (Product item in batch)
            {
                cosmosResult = cosmosResult + item.Name + ", ";
            }
        }

        ViewBag.sql = cosmosResult;

        return View();
    }

    public IActionResult ErrorPage()
    {
        var answer = 42;
        var result = answer / 0;
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
