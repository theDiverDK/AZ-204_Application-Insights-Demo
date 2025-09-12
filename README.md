Source code and Azure devops to deploy Application Insights Demo

The code is purely for demo purpose, and the 'division by zero' is meant to show exceptiobn logging in Application Insights.

Feel free to use the Bicep modules, and please send new ones.


When running the pipeline to deploy to Azure, there is a bug where it fails the first time, informing the app insight is not found, but it's already created.
Running a second time works well.
