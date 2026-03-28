using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class BlogPost
{
    public int Id { get; set; }

    public int? AuthorId { get; set; }

    public int? DestinationId { get; set; }

    public string? Title { get; set; }

    public string? ContentHtml { get; set; }

    public string? ThumbnailUrl { get; set; }

    public DateTime? PublishedAt { get; set; }

    public virtual User? Author { get; set; }

    public virtual Destination? Destination { get; set; }
}


