using System.Diagnostics;
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Mvc;

using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.Cosmos;
using Microsoft.Data.SqlClient;
using WebApplication1.Models;

namespace Application_Insight.Controllers;

class Product
{

    public string? Name { get; set; }
    public string? id { get; set; }
    public int Age { get; set; }
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

        var containerClient = new BlobContainerClient(storageAccountConnectionString, storageAccountContainerName);

        var data = containerClient.GetBlobs();

        var result = string.Join(", ", data.Select(item => item.Name));

        ViewBag.data = result;

        var cosmosDbConnectionString = _config["ConnectionStrings:CosmosDB"];
        var cosmosDbName = _config["Settings:CosmosDBDatabaseName"];
        var cosmosContainerName = _config["Settings:CosmosDBContainerName"];

        var client = new CosmosClient(cosmosDbConnectionString);
        var db = client.GetDatabase(cosmosDbName);
        var container = db.GetContainer(cosmosContainerName);
        var queryText = "SELECT * FROM c";
        var query = new QueryDefinition(queryText);
        _telemetry.TrackTrace("CosmosDB SQL query executed", SeverityLevel.Information, new Dictionary<string, string>
        {
            ["db.system"] = "cosmosdb",
            ["db.name"] = cosmosDbName ?? string.Empty,
            ["db.container"] = cosmosContainerName ?? string.Empty,
            ["db.statement"] = query.QueryText
        });

        FeedIterator<Product> iterator = container.GetItemQueryIterator<Product>(query);

        var cosmosResult = "";
        // Iterate over results
        while (iterator.HasMoreResults)
        {
               FeedResponse<Product> batch =  iterator.ReadNextAsync().GetAwaiter().GetResult();
               var cosmosQueryPageTelemetry = new EventTelemetry("CosmosDB query page");
               cosmosQueryPageTelemetry.Properties["db.system"] = "cosmosdb";
               cosmosQueryPageTelemetry.Properties["db.name"] = cosmosDbName ?? string.Empty;
               cosmosQueryPageTelemetry.Properties["db.container"] = cosmosContainerName ?? string.Empty;
               cosmosQueryPageTelemetry.Properties["db.cosmosdb.request_charge"] = batch.RequestCharge.ToString();

               _telemetry.TrackEvent(cosmosQueryPageTelemetry);

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
