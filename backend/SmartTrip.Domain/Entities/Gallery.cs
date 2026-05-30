using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Gallery
{
    public int Id { get; set; }

    public GalleryReferenceType? ReferenceType { get; set; }

    public int? ReferenceId { get; set; }

    public string? ImageUrl { get; set; }
}



