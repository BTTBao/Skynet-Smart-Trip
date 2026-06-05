import os

file_path = r"c:\6451071003\GitHub\Skynet-Smart-Trip\backend\SmartTrip.Application\Services\Trip\ItineraryService.cs"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace the calls
content = content.replace("await RecalculateTripTotalsAsync(tripId);", "await RecalculateTripTotalsWithPaymentsAsync(tripId);")
content = content.replace("await RecalculateTripTotalsAsync(tripId.Value);", "await RecalculateTripTotalsWithPaymentsAsync(tripId.Value);")

lines = content.splitlines()

# Let's search for "private async Task RecalculateTripTotalsAsync"
index = -1
for i, line in enumerate(lines):
    if "private async Task RecalculateTripTotalsAsync" in line:
        index = i
        break

if index != -1:
    print(f"Found RecalculateTripTotalsAsync at line {index}")
    # Find the end of this method (the closing brace '}' at column 4)
    end_index = -1
    for j in range(index, len(lines)):
        if lines[j].strip() == "}":
            # Check if this is the closing brace
            # Let's count braces or look for the next method
            # Usually the method is short. Let's find the closing brace.
            # In our case, the method closes at 14 lines below.
            end_index = j
            break
            
    if end_index != -1:
        print(f"Closing brace found at line {end_index}")
        # Insert the new method right after the closing brace
        new_method = """

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
        
        lines.insert(end_index + 1, new_method)
        # determine line endings
        eol = "\r\n" if "\r\n" in content else "\n"
        new_content = eol.join(lines)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("Successfully updated ItineraryService.cs!")
    else:
        print("ERROR: Closing brace not found!")
else:
    print("ERROR: RecalculateTripTotalsAsync not found!")
