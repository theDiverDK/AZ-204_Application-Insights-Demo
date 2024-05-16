using System.Diagnostics;
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
        var containerConnectionsString=_config.GetConnectionString("StorageAccountConnectionString");// ("https://sasaccount0702.blob.core.windows.net/demo");

        var containerClient = new BlobContainerClient("DefaultEndpointsProtocol=https;AccountName=az204testst;AccountKey=XZw+RGFIQ0YJ5uOJBwkgR3RDUyHCzaZP/KXQSOEYSj6Iv+0pROJymvx/Kf2gAetLQQAvpaO9eh7R+AStR+H5QQ==;EndpointSuffix=core.windows.net", "files");

        var data = containerClient.GetBlobs();

        var result = string.Join(", ", data.Select(item => item.Name));

        ViewBag.data = result;

        var client = new CosmosClient("AccountEndpoint=https://az204-test-cosmosdb.documents.azure.com:443/;AccountKey=Tp3EXDBVut6PeTxcV9z0EcCnusECcpnzTl7yDnZgarwS7YfoPUI9wqDwFnU3FjK60dyqjnSXaTGrACDbrJCKNA==;");//_config.GetConnectionString("CosmosDBConnectionString"));
        var db = client.GetDatabase("az204-test-database");
        var container = db.GetContainer("az204-test-container");

// Use SQL query language
        FeedIterator<Product> iterator = container.GetItemQueryIterator<Product>(
            "SELECT * FROM c"
        );

        var cosmosResult = "";
        // Iterate over results
        while (iterator.HasMoreResults)
        {
               FeedResponse<Product> batch =  iterator.ReadNextAsync().GetAwaiter().GetResult();
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