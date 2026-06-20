using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using SmartTrip.Application.Interfaces.Storage;

namespace SmartTrip.API.Filters;

public sealed class ImageStorageExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        if (context.Exception is not ImageStorageUnavailableException exception)
        {
            return;
        }

        context.Result = new ObjectResult(new { message = exception.Message })
        {
            StatusCode = StatusCodes.Status503ServiceUnavailable
        };
        context.ExceptionHandled = true;
    }
}
