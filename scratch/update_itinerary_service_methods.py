import os

file_path = r"c:\6451071003\GitHub\Skynet-Smart-Trip\backend\SmartTrip.Application\Services\Trip\ItineraryService.cs"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace RecalculateTripTotalsAsync calls
content = content.replace("await RecalculateTripTotalsAsync(tripId);", "await RecalculateTripTotalsWithPaymentsAsync(tripId);")
content = content.replace("await RecalculateTripTotalsAsync(tripId.Value);", "await RecalculateTripTotalsWithPaymentsAsync(tripId.Value);")

# Find the end of RecalculateTripTotalsAsync method to insert RecalculateTripTotalsWithPaymentsAsync
old_recalc = """    private async Task RecalculateTripTotalsAsync(int tripId)
    {
        var trip = await _context.Trips
            .Include(item => item.TripItineraries)
            .FirstAsync(item => item.Id == tripId);

        trip.TotalAmount = trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

        trip.TotalProfit = trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) *
            NormalizeCommissionRate(item.BookedCommissionRate) *
            (item.Quantity ?? 1));

        await _context.SaveChangesAsync();
    }"""

new_recalc = old_recalc + """

    private async Task RecalculateTripTotalsWithPaymentsAsync(int tripId)
    {
        var trip = await _context.Trips
            .Include(item => item.TripItineraries)
            .Include(item => item.Payments)
            .FirstOrDefaultAsync(item => item.Id == tripId);

        if (trip == null) return;

        trip.TotalAmount = trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

        var totalPaidAmount = trip.Payments
            .Where(p => p.Status == PaymentStatus.Paid)
            .Sum(p => p.Amount ?? 0m);

        if (totalPaidAmount <= 0)
        {
            trip.TotalProfit = 0m;
        }
        else
        {
            var grossAmount = trip.TripItineraries.Sum(item =>
                (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

            if (grossAmount <= 0)
            {
                trip.TotalProfit = 0m;
            }
            else
            {
                trip.TotalProfit = trip.TripItineraries.Sum(item =>
                {
                    var lineGross = (item.BookedPrice ?? 0) * (item.Quantity ?? 1);
                    var paidLineAmount = totalPaidAmount * lineGross / grossAmount;
                    return paidLineAmount * NormalizeCommissionRate(item.BookedCommissionRate);
                });
            }
        }

        await _context.SaveChangesAsync();
    }"""

def normalize(s):
    return s.replace("\r\n", "\n").replace("\r", "\n").strip()

normalized_content = normalize(content)
normalized_old_recalc = normalize(old_recalc)

if normalized_old_recalc in normalized_content:
    print("Found old RecalculateTripTotalsAsync!")
    content = content.replace(old_recalc, new_recalc)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Success updating methods!")
else:
    print("ERROR: Could not find old RecalculateTripTotalsAsync in file!")
