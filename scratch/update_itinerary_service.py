import os

file_path = r"c:\6451071003\GitHub\Skynet-Smart-Trip\backend\SmartTrip.Application\Services\Trip\ItineraryService.cs"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Define the old UpdateItineraryAsync code
old_update = """    public async Task<TripItineraryDto> UpdateItineraryAsync(int itineraryId, UpdateTripItineraryDto request)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(item => item.Id == itineraryId);
        if (itinerary == null)
        {
            throw new KeyNotFoundException($"Itinerary {itineraryId} was not found.");
        }

        if (request.DayNumber.HasValue)
        {
            var trip = await _context.Trips.FirstAsync(item => item.Id == itinerary.TripId);
            ValidateDayNumber(trip, request.DayNumber.Value);
            itinerary.DayNumber = request.DayNumber.Value;
        }

        if (request.Quantity.HasValue)
        {
            itinerary.Quantity = request.Quantity.Value;
        }

        if (request.BookedPrice.HasValue)
        {
            itinerary.BookedPrice = request.BookedPrice.Value;
        }

        if (request.BookedCommissionRate.HasValue)
        {
            itinerary.BookedCommissionRate = request.BookedCommissionRate.Value;
        }

        if (request.ServiceDate.HasValue)
        {
            itinerary.ServiceDate = request.ServiceDate.Value;
        }

        if (request.DepartureTime.HasValue)
        {
            itinerary.DepartureTime = request.DepartureTime.Value;
        }

        if (request.ServiceAddress != null)
        {
            itinerary.ServiceAddress = request.ServiceAddress;
        }

        await _context.SaveChangesAsync();
        if (itinerary.TripId.HasValue)
        {
            await RecalculateTripTotalsAsync(itinerary.TripId.Value);
        }

        return await MapItineraryAsync(itinerary);
    }"""

# Define the new UpdateItineraryAsync code
new_update = """    public async Task<TripItineraryDto> UpdateItineraryAsync(int itineraryId, UpdateTripItineraryDto request)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(item => item.Id == itineraryId);
        if (itinerary == null)
        {
            throw new KeyNotFoundException($"Itinerary {itineraryId} was not found.");
        }

        if (request.TripId.HasValue && request.TripId.Value != itinerary.TripId)
        {
            var newTrip = await _context.Trips.FirstOrDefaultAsync(t => t.Id == request.TripId.Value);
            if (newTrip == null)
            {
                throw new KeyNotFoundException($"Target Trip {request.TripId.Value} was not found.");
            }

            var oldTripId = itinerary.TripId;
            itinerary.TripId = request.TripId.Value;

            if (request.DayNumber.HasValue)
            {
                itinerary.DayNumber = request.DayNumber.Value;
            }
            else
            {
                itinerary.DayNumber = 1;
            }

            // Move payments and invoices associated with old trip to new trip
            if (oldTripId.HasValue)
            {
                var payments = await _context.Payments
                    .Where(p => p.TripId == oldTripId.Value)
                    .ToListAsync();
                foreach (var payment in payments)
                {
                    payment.TripId = request.TripId.Value;
                }

                var invoices = await _context.Invoices
                    .Where(i => i.TripId == oldTripId.Value)
                    .ToListAsync();
                foreach (var invoice in invoices)
                {
                    invoice.TripId = request.TripId.Value;
                }
            }

            await _context.SaveChangesAsync();

            // Recalculate totals and profit for both trips
            if (oldTripId.HasValue)
            {
                await RecalculateTripTotalsWithPaymentsAsync(oldTripId.Value);

                // If old trip was BOOKING_ONLY and now has no itineraries, delete it
                var oldTrip = await _context.Trips
                    .Include(t => t.TripItineraries)
                    .FirstOrDefaultAsync(t => t.Id == oldTripId.Value);
                if (oldTrip != null && oldTrip.Status == TripStatus.BookingOnly && !oldTrip.TripItineraries.Any())
                {
                    _context.Trips.Remove(oldTrip);
                    await _context.SaveChangesAsync();
                }
            }

            await RecalculateTripTotalsWithPaymentsAsync(request.TripId.Value);
        }
        else
        {
            if (request.DayNumber.HasValue)
            {
                var trip = await _context.Trips.FirstAsync(item => item.Id == itinerary.TripId);
                ValidateDayNumber(trip, request.DayNumber.Value);
                itinerary.DayNumber = request.DayNumber.Value;
            }
        }

        if (request.Quantity.HasValue)
        {
            itinerary.Quantity = request.Quantity.Value;
        }

        if (request.BookedPrice.HasValue)
        {
            itinerary.BookedPrice = request.BookedPrice.Value;
        }

        if (request.BookedCommissionRate.HasValue)
        {
            itinerary.BookedCommissionRate = request.BookedCommissionRate.Value;
        }

        if (request.ServiceDate.HasValue)
        {
            itinerary.ServiceDate = request.ServiceDate.Value;
        }

        if (request.DepartureTime.HasValue)
        {
            itinerary.DepartureTime = request.DepartureTime.Value;
        }

        if (request.ServiceAddress != null)
        {
            itinerary.ServiceAddress = request.ServiceAddress;
        }

        await _context.SaveChangesAsync();

        if (itinerary.TripId.HasValue && (!request.TripId.HasValue || request.TripId.Value == itinerary.TripId))
        {
            await RecalculateTripTotalsWithPaymentsAsync(itinerary.TripId.Value);
        }

        return await MapItineraryAsync(itinerary);
    }"""

# Normalization helper for CRLF / LF
def normalize(s):
    return s.replace("\r\n", "\n").replace("\r", "\n").strip()

normalized_content = normalize(content)
normalized_old = normalize(old_update)

if normalized_old in normalized_content:
    print("Found old UpdateItineraryAsync!")
    # We replace it
    new_content = content.replace(old_update, new_update)
    if new_content == content:
        # try replacing with normalized line endings
        content_lines = content.splitlines()
        old_lines = old_update.splitlines()
        # Find where it starts
        for i in range(len(content_lines) - len(old_lines) + 1):
            match = True
            for j in range(len(old_lines)):
                if content_lines[i+j].strip() != old_lines[j].strip():
                    match = False
                    break
            if match:
                print(f"Matched lines starting at index {i}")
                # Replace these lines
                content_lines[i:i+len(old_lines)] = new_update.splitlines()
                new_content = "\\n".join(content_lines)
                # determine original line endings
                if "\\r\\n" in content:
                    new_content = "\\r\\n".join(content_lines)
                else:
                    new_content = "\\n".join(content_lines)
                break
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("Replaced UpdateItineraryAsync successfully!")
else:
    print("ERROR: Could not find old UpdateItineraryAsync in file!")
