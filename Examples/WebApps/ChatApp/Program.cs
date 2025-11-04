using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

var builder = WebApplication.CreateBuilder(args);

// Add Semantic Kernel with Azure OpenAI
builder.Services.AddKernel()
    .AddAzureOpenAIChatCompletion(
        deploymentName: builder.Configuration["AZURE_OPENAI_DEPLOYMENT_NAME"],
        endpoint: builder.Configuration["AZURE_OPENAI_ENDPOINT"],
        apiKey: builder.Configuration["AZURE_OPENAI_API_KEY"]
    );

var app = builder.Build();

app.MapPost("/chat", async (string message, Kernel kernel) =>
{
    var chatService = kernel.GetRequiredService<IChatCompletionService>();
    var response = await chatService.GetChatMessageContentAsync(message);
    return Results.Ok(new { response = response.Content });
});

app.MapGet("/", () => Results.Ok(new { 
    message = "Chat application is running. POST to /chat with a message to interact.",
    example = "POST /chat { \"message\": \"Hello!\" }"
}));

app.Run();
