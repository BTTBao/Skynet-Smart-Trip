using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Gallery
{
    public int PhotoId { get; set; }

    public string? ReferenceType { get; set; }

    public int? ReferenceId { get; set; }

    public string? ImageUrl { get; set; }
}
