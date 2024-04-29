using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Azure.Storage.Blobs;
using Microsoft.Azure.Cosmos;
using Microsoft.AspNetCore.Authorization;
using WebApplication1.Models;

namespace Application_Insight.Controllers;

class Product
{
    public string? Name
    {
        get;
        set;
    }
}

[Authorize]
public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;

    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }

    public IActionResult Index()
    {
        //HttpContext.Features.Get<RequestTelemetry>().Properties["myProp"] = "Dette er noget data";
        return View();
    }

    public IActionResult Privacy()
    {
        var containerClient = new BlobContainerClient("DefaultEndpointsProtocol=https;AccountName=azblob0703;AccountKey=G+Y4jQQIeokeVxDLYJmz2RvWebsT93kzvxfsrvo6HVa6lA/4IjeXQFi5fc9ovW0lyFXOOZ03tsMR+AStKmwGnQ==;EndpointSuffix=core.windows.net", "demo");

        var data = containerClient.GetBlobs();

        var result = string.Join(", ", data.Select(item => item.Name));

        ViewBag.data = result;

        var client = new CosmosClient("AccountEndpoint=https://appinsightcosmos.documents.azure.com:443/;AccountKey=H8rvVUBI1qF5kB4TJbVtqE4zPm5ZUBV52ohzxES1JAZZ4N9InCWmKbVVAPuogRIE8K6C81u67MZYACDbmWIO5Q==;");
        var db = client.GetDatabase("ToDoList");
        var container = db.GetContainer("demo");

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

    [AllowAnonymous]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}