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

    public string Name { get; set; }
    public string id { get; set; }
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
        var containerConnectionsString=_config.GetConnectionString("StorageAccountConnectionString");// ("https://sasaccount0702.blob.core.windows.net/demo");

        var containerClient = new BlobContainerClient("DefaultEndpointsProtocol=https;AccountName=az204testst;AccountKey=Ttc0BSS7ZYLBb2/R+L8fyWOFKPFLst9d0hluhs8DTWoZzgSVLqF8gnBb4A2AX0Lo/R2JshAXqXml+ASt642tDg==;EndpointSuffix=core.windows.net", "files");

        var data = containerClient.GetBlobs();

        var result = string.Join(", ", data.Select(item => item.Name));

        ViewBag.data = result;

        var client = new CosmosClient("AccountEndpoint=https://az204-test-cosmosdb.documents.azure.com:443/;AccountKey=WAzQi9Rf5q4B5dXIIDWnflwjf68UNa0olnxR4hSz0M67LaqWHfYvweQgkZO4GWkp1QxZeTCiFIGdACDbuhXI3g==;");//_config.GetConnectionString("CosmosDBConnectionString"));
        var db = client.GetDatabase("az204-test-database");
        var container = db.GetContainer("az204-test-container");

        var cosmosDbName = "az204-test-database";
        var cosmosContainerName = "az204-test-container";
        var queryText = "SELECT * FROM c";
        var query = new QueryDefinition(queryText);
        _telemetry.TrackTrace("CosmosDB SQL query executed", SeverityLevel.Information, new Dictionary<string, string>
        {
            ["db.system"] = "cosmosdb",
            ["db.name"] = cosmosDbName,
            ["db.container"] = cosmosContainerName,
            ["db.statement"] = query.QueryText
        });

        FeedIterator<Product> iterator = container.GetItemQueryIterator<Product>(query);

        var cosmosResult = "";
        // Iterate over results
        while (iterator.HasMoreResults)
        {
               FeedResponse<Product> batch =  iterator.ReadNextAsync().GetAwaiter().GetResult();
               _telemetry.TrackEvent("CosmosDB query page", new Dictionary<string, string>
               {
                   ["db.system"] = "cosmosdb",
                   ["db.name"] = cosmosDbName,
                   ["db.container"] = cosmosContainerName
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
