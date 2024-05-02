using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Application_Insight.Models;
using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.Cosmos;
using Microsoft.Data.SqlClient;

namespace Application_Insight.Controllers;

class Product
{
    public string navn {
        get;
        set;
    }
}

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;

    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }

    public IActionResult Index()
    {
        HttpContext.Features.Get<RequestTelemetry>().Properties["myProp"] = "Dette er noget data";
        return View();
    }

    public IActionResult Privacy()
    {
        var containerEndpoint = ("https://sasaccount0702.blob.core.windows.net/demo");

        var containerClient = new BlobContainerClient(new Uri(containerEndpoint), new DefaultAzureCredential());

        var data = containerClient.GetBlobs();

        var result = string.Join(", ", data.Select(item => item.Name));

        ViewBag.data = result;

        var client = new CosmosClient("AccountEndpoint=https://appinsightcosmoms.documents.azure.com:443/;AccountKey=mmcWzekNYizQDiH0VELdt5kZToT6XUBGwwWeVLr188KLxPV3JHfrNJpbwmooudQUXInUenl0VQAVACDbiQe5LQ==;");
        var db = client.GetDatabase("ToDoList");
        var container = db.GetContainer("test");

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
                   cosmosResult = cosmosResult + item.navn + ", ";
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