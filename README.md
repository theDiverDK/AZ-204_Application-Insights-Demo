# AZ-204 Application Insights Demo

An Azure learning demo that provisions an Application Insights-backed web workload and supporting Azure resources. It is intended for experimenting with telemetry, availability checks, alerts, and exception monitoring in the context of AZ-204.

> The deliberate divide-by-zero scenario is included to demonstrate exception logging in Application Insights. It is not production code.

## What's included

- Bicep modules in [`.azure/bicep`](.azure/bicep) for Application Insights, Log Analytics, App Service, Functions, Storage, Cosmos DB, Key Vault, RBAC, alerts, and availability tests.
- Two ASP.NET Core web applications in [`src/WebApps`](src/WebApps).
- Azure DevOps pipeline definitions in [`.ado/pipelines`](.ado/pipelines).
- Python seed scripts for the Cosmos DB and Storage Account demo data.

## Prerequisites

- .NET SDK version specified in [`global.json`](global.json)
- Azure CLI, authenticated to the subscription used for the demo
- Bicep CLI (included with recent Azure CLI versions)
- An Azure DevOps project if you want to run the included pipelines

## Run locally

Choose either application under `src/WebApps`, then restore and run it. For example:

```bash
dotnet run --project src/WebApps/Application_Insight/Application_Insight.csproj
```

Local execution is useful for exploring the application. Azure telemetry and resource configuration require deployment of the accompanying infrastructure.

## Deploying the infrastructure

The Bicep entry point is [`infrastructure.bicep`](.azure/bicep/infrastructure.bicep). Review its parameters and every resource name before deployment, then deploy it to a resource group appropriate for your subscription. The Azure DevOps pipeline files show the intended automated deployment flow.

## Repository layout

```text
.azure/bicep/       Infrastructure modules
.ado/pipelines/     Azure DevOps pipeline definitions and seed scripts
src/WebApps/        ASP.NET Core demo applications
```

## Contributing

This is a teaching project. Improvements to the Bicep modules, telemetry examples, or documentation are welcome through issues and pull requests.
