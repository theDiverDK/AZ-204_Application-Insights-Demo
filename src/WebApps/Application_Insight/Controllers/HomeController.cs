using System.Diagnostics;
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

    public HomeController(ILogger<HomeController> logger, IConfiguration config)
    {
        _logger = logger;
        _config = config;
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

        // Use SQL query language
        FeedIterator<Product> iterator = container.GetItemQueryIterator<Product>(
            "SELECT * FROM c"
        );

        var cosmosResult = "";
        // Iterate over results
        while (iterator.HasMoreResults)
        {
            FeedResponse<Product> batch = iterator.ReadNextAsync().GetAwaiter().GetResult();
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