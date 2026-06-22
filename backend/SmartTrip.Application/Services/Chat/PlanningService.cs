using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Services.Chat;

/// <summary>
/// Layer 3 — Conditional plan generation.
/// Core principle: ONLY generate plan when ALL required data is available.
/// Required: destination (in DB), origin, traveler count, budget.
/// NEVER generates "generic" plans from fabricated data.
/// </summary>
public class PlanningService
{
    private readonly IChatRepository _chatRepo;

    public PlanningService(IChatRepository chatRepo)
    {
        _chatRepo = chatRepo;
    }

    // ──────────────────────────────────────────────
    // PLAN READINESS CHECK — GATE BEFORE PLAN GENERATION
    // ──────────────────────────────────────────────

    public PlanReadiness CheckPlanReadiness(
        ChatEntitiesDto entities,
        LocationMatchResult location,
        string userMessage,
        List<ChatHistoryItemDto> history)
    {
        var readiness = new PlanReadiness();

        // 1. Destination — MUST match in DB
        if (!location.IsExactMatch)
        {
            if (!string.IsNullOrWhiteSpace(location.RequestedLocation))
            {
                var availableNames = location.AllDestinations
                    .Select(d => d.Name)
                    .Where(n => !string.IsNullOrWhiteSpace(n))
                    .Take(5)
                    .ToList();

                var suggestion = availableNames.Count > 0
                    ? $" Hiện hệ thống có: {string.Join(", ", availableNames)}"
                    : string.Empty;

                readiness.MissingFields.Add(
                    $"điểm đến '{location.RequestedLocation}' chưa có trong hệ thống.{suggestion} Bạn muốn chn điểm nào");
            }
            else
            {
                readiness.MissingFields.Add("bạn muốn đi đâu");
            }
        }
        else
        {
            readiness.Destinations = location.ExactMatches;
        }

        // 2. Origin
        var origin = entities.Origin;
        if (string.IsNullOrWhiteSpace(origin))
        {
            readiness.MissingFields.Add("bạn đi từ đâu");
        }
        else
        {
            readiness.Origin = origin;
        }

        // 3. Traveler count
        if (entities.PassengerCount.HasValue)
        {
            readiness.TravelerCount = entities.PassengerCount.Value;
        }
        else
        {
            readiness.MissingFields.Add("có bao nhiêu người đi");
        }

        // 4. Budget
        if (entities.Budget.HasValue)
        {
            readiness.Budget = entities.Budget.Value;
        }
        else
        {
            readiness.MissingFields.Add("ngân sách dự kiến bao nhiêu");
        }

        // 5. Departure Date
        var departureDate = entities.DepartureDate;
        if (string.IsNullOrWhiteSpace(departureDate))
        {
            readiness.MissingFields.Add("ngày bắt đầu đi");
        }
        else
        {
            readiness.DepartureDate = departureDate;
        }

        // 6. Days (optional — default 3)
        readiness.RequestedDays = entities.Days ?? 3;

        readiness.IsReady = readiness.MissingFields.Count == 0;

        if (!readiness.IsReady)
        {
            readiness.FollowUpQuestion = BuildFollowUpQuestion(
                readiness.Destinations.FirstOrDefault()?.Name,
                readiness.RequestedDays,
                readiness.MissingFields);
        }

        return readiness;
    }

    // ──────────────────────────────────────────────
    // PLAN BUILDER — ONLY RUNS WHEN READY
    // ──────────────────────────────────────────────

    public async Task<ChatResponseDto> BuildPlan(
        PlanReadiness readiness,
        KnowledgeResult knowledge,
        ChatUserProfileDto? userProfile)
    {
        var destination = readiness.Destinations.First();
        var currency = userProfile?.PreferredCurrency ?? "VND";
        var travelerCount = readiness.TravelerCount ?? 2;
        var requestedDays = readiness.RequestedDays;

        // Get real hotel and bus data
        var hotels = knowledge.Hotels ?? await _chatRepo.SearchDestinationsHotelsAsync(
            [destination.Id], 6);

        var targetDate = DateOnly.TryParse(readiness.DepartureDate, out var date)
            ? date
            : DateOnly.FromDateTime(DateTime.UtcNow);

        var buses = knowledge.BusSchedules ?? (await _chatRepo.GetBusSchedulesAsync(
            10, [destination.Id]))
            .Where(r => r.DepartureTime.HasValue
                && DateOnly.FromDateTime(r.DepartureTime.Value.ToLocalTime()) == targetDate)
            .OrderBy(r => r.DepartureTime)
            .ToList();

        // Select preferred hotel (from entity or first available)
        var selectedHotel = hotels
            .Where(h => h != null)
            .OrderBy(h => KnowledgeService.GetLowestHotelPrice(h) ?? decimal.MaxValue)
            .ThenByDescending(h => h.StarRating)
            .FirstOrDefault();
        var selectedBus = SelectPreferredBusSchedule(buses, readiness.Origin, destination);

        var costBreakdown = BuildCostBreakdown(
            selectedHotel, selectedBus,
            requestedDays, travelerCount, currency);

        var itinerary = new ItineraryDto
        {
            Title = $"Lịch trình gợi ý tại {destination.Name}",
            Destination = destination.Name,
            DestinationId = destination.Id,
            TotalDays = requestedDays,
            EstimatedBudget = BuildBudgetSummaryLabel(
                costBreakdown, travelerCount, currency, readiness.Budget),
            TravelStyle = "Linh hoạt",
            HotelSuggestion = BuildHotelSuggestion(selectedHotel),
            TransportSuggestion = BuildTransportSuggestion(selectedBus),
            CostBreakdown = costBreakdown,
            Days = BuildItineraryDays(
                destination, selectedHotel, selectedBus,
                requestedDays, travelerCount, currency,
                readiness.Origin)
        };

        var responseText = BuildItinerarySummaryText(itinerary);

        // Budget warning if exceeded
        if (readiness.Budget.HasValue
            && costBreakdown.TotalCost.HasValue
            && costBreakdown.TotalCost.Value > readiness.Budget.Value)
        {
            responseText += $"\n Tổng chi phí ước tính " +
                $"({KnowledgeService.FormatCurrency(costBreakdown.TotalCost, currency)}) " +
                $"vượt ngân sách ({KnowledgeService.FormatCurrency(readiness.Budget, currency)}). " +
                "Bạn có muốn mình điu chỉnh cho phù hợp hơn không?";
        }

        return new ChatResponseDto
        {
            Text = responseText,
            ResponseType = "itinerary",
            SuggestedItinerary = itinerary
        };
    }

    // ──────────────────────────────────────────────
    // COST CALCULATION
    // ──────────────────────────────────────────────

    private static ItineraryCostBreakdownDto BuildCostBreakdown(
        Hotel? hotel,
        BusSchedule? bus,
        int requestedDays,
        int travelerCount,
        string? currency)
    {
        var headCount = Math.Max(1, travelerCount);
        var nights = Math.Max(1, requestedDays - 1);
        var roomsNeeded = GetEstimatedRoomCount(hotel, headCount);
        var hotelCost = hotel == null
            ? null
            : GetEstimatedStayCost(KnowledgeService.GetLowestHotelPrice(hotel), nights) * roomsNeeded;
        var transportCost = bus?.Price * headCount;
        var foodCost = 180000m * headCount * Math.Max(1, requestedDays);
        var activityCost = 140000m * headCount * Math.Max(1, requestedDays);
        var totalCost = (hotelCost ?? 0) + (transportCost ?? 0) + foodCost + activityCost;

        return new ItineraryCostBreakdownDto
        {
            HotelCost = hotelCost,
            TransportCost = transportCost,
            FoodCost = foodCost,
            ActivityCost = activityCost,
            TotalCost = totalCost,
            Currency = string.IsNullOrWhiteSpace(currency) ? "VND" : currency!
        };
    }

    // ──────────────────────────────────────────────
    // ITINERARY DAY BUILDER — FROM REAL DB DATA
    // ──────────────────────────────────────────────

    private static List<ItineraryDayDto> BuildItineraryDays(
        Destination destination,
        Hotel? hotel,
        BusSchedule? bus,
        int requestedDays,
        int travelerCount,
        string? currency,
        string? origin)
    {
        var totalDays = Math.Max(1, requestedDays);
        var headCount = Math.Max(1, travelerCount);
        var hotelNightly = KnowledgeService.GetLowestHotelPrice(hotel);
        var roomsNeeded = GetEstimatedRoomCount(hotel, headCount);
        var hotelNightlyTotal = hotelNightly.HasValue
            ? hotelNightly.Value * roomsNeeded
            : (decimal?)null;
        var transportTotal = bus?.Price.HasValue == true
            ? bus.Price!.Value * headCount
            : (decimal?)null;
        var mealCost = 90000m * headCount;
        var dinnerCost = 120000m * headCount;
        var cafeCost = 60000m * headCount;
        var activityCost = 140000m * headCount;
        var days = new List<ItineraryDayDto>();

        for (var dayNumber = 1; dayNumber <= totalDays; dayNumber++)
        {
            if (dayNumber == 1)
            {
                days.Add(BuildDay1(destination, hotel, bus,
                    headCount, roomsNeeded, hotelNightlyTotal,
                    transportTotal, dinnerCost, currency, origin));
                continue;
            }

            if (dayNumber == totalDays)
            {
                days.Add(BuildLastDay(destination, hotel, bus,
                    totalDays, headCount, mealCost, cafeCost,
                    activityCost, transportTotal, currency, origin));
                continue;
            }

            days.Add(BuildMiddleDay(destination, dayNumber,
                headCount, mealCost, dinnerCost, cafeCost,
                activityCost, currency));
        }

        return days;
    }

    private static ItineraryDayDto BuildDay1(
        Destination destination, Hotel? hotel, BusSchedule? bus,
        int headCount, int roomsNeeded, decimal? hotelNightlyTotal,
        decimal? transportTotal, decimal dinnerCost,
        string? currency, string? origin)
    {
        return new ItineraryDayDto
        {
            DayNumber = 1,
            Theme = "Di chuyển và nhận phòng",
            Activities = new List<ItineraryActivityDto>
            {
                new()
                {
                    Time = "08:00",
                    Title = bus != null
                        ? $"{bus.Company?.Name ?? "Xe khách"} đến {destination.Name}"
                        : $"Di chuyển đến {destination.Name}",
                    Description = bus != null
                        ? $"Tuyến {origin ?? bus.FromDest?.Name ?? "điểm khởi hành"} -> {bus.ToDest?.Name ?? destination.Name}, khởi hành {KnowledgeService.FormatDateTime(bus.DepartureTime)}."
                        : $"Khởi hành từ {origin ?? "điểm xuất phát"} để đến {destination.Name}.",
                    Icon = "transport",
                    EstimatedCost = KnowledgeService.FormatCurrency(transportTotal, currency)
                },
                new()
                {
                    Time = "14:00",
                    Title = !string.IsNullOrWhiteSpace(hotel?.Name)
                        ? $"Nhận phòng tại {hotel!.Name}"
                        : "Nhận phòng và nghỉ ngơi",
                    Description = !string.IsNullOrWhiteSpace(hotel?.Name)
                        ? BuildHotelDayDescription(hotel!, roomsNeeded)
                        : "Nhận phòng tại khách sạn phù hợp gần trung tâm.",
                    Icon = "hotel",
                    EstimatedCost = hotelNightlyTotal == null
                        ? null
                        : $"{KnowledgeService.FormatCurrency(hotelNightlyTotal, currency)} / đêm"
                },
                new()
                {
                    Time = "19:00",
                    Title = "Ăn tối và đi dạo buổi tối",
                    Description = destination.Name switch
                    {
                        "Đà Lạt"   => "Nhận phòng sớm, uống cà phê nóng và dạo khu trung tâm để làm quen nhịp chuyển đổi.",
                        "Vũng Tàu" => "Nhận phòng, đi dạo biển và ngắm hoàng hôn ở bãi Sau.",
                        "Đà Nẵng"  => "Nhận phòng rồi ghé biển Mỹ Khê hoặc cầu Rồng buổi tối.",
                        "Hà Nội"   => "Nhận phòng, dạo phố cổ và thưởng thức ẩm thực tối.",
                        "Nha Trang"=> "Nhận phòng rồi đi biển nhẹ, nghỉ ngơi và chuẩn bị cho ngày khám phá.",
                        _          => $"Nhận phòng và tranh thủ khám phá nhẹ khu trung tâm của {destination.Name}."
                    },
                    Icon = "restaurant",
                    EstimatedCost = KnowledgeService.FormatCurrency(dinnerCost, currency)
                }
            }
        };
    }

    private static ItineraryDayDto BuildLastDay(
        Destination destination, Hotel? hotel, BusSchedule? bus,
        int totalDays, int headCount, decimal mealCost,
        decimal cafeCost, decimal activityCost,
        decimal? transportTotal, string? currency, string? origin)
    {
        return new ItineraryDayDto
        {
            DayNumber = totalDays,
            Theme = "Thư giãn và kết thúc hành trình",
            Activities = new List<ItineraryActivityDto>
            {
                new()
                {
                    Time = "08:30",
                    Title = "Ăn sáng và check-out",
                    Description = !string.IsNullOrWhiteSpace(hotel?.Name)
                        ? $"Dùng bữa sáng, trả phòng tại {hotel.Name} và kiểm tra hành lý trước khi rời đi {destination.Name}."
                        : $"Dùng bữa sáng và trả phòng trước khi kết thúc hành trình tại {destination.Name}.",
                    Icon = "hotel",
                    EstimatedCost = KnowledgeService.FormatCurrency(mealCost, currency)
                },
                new()
                {
                    Time = "10:30",
                    Title = "Mua đặc sản và chụp ảnh lần cuối",
                    Description = $"Dành ít thi gian ghé chợ đặc sản hoặc quán cà phê view đẹp để có thêm ảnh kỷ niệm.",
                    Icon = "shopping",
                    EstimatedCost = KnowledgeService.FormatCurrency(cafeCost + activityCost, currency)
                },
                new()
                {
                    Time = "13:30",
                    Title = "Di chuyển về khách sạn",
                    Description = $"Kết thúc lịch trình {totalDays} ngày tại {destination.Name} và quay về {origin ?? "điểm xuất phát"}.",
                    Icon = "transport",
                    EstimatedCost = KnowledgeService.FormatCurrency(transportTotal, currency)
                }
            }
        };
    }

    private static ItineraryDayDto BuildMiddleDay(
        Destination destination, int dayNumber, int headCount,
        decimal mealCost, decimal dinnerCost, decimal cafeCost,
        decimal activityCost, string? currency)
    {
        return new ItineraryDayDto
        {
            DayNumber = dayNumber,
            Theme = "Khám phá điểm đến",
            Activities = new List<ItineraryActivityDto>
            {
                new()
                {
                    Time = "07:30",
                    Title = "Ăn sáng địa phương",
                    Description = $"Thử bữa sáng đặc trưng tại khu trung tâm {destination.Name} để bắt đầu ngày mới.",
                    Icon = "restaurant",
                    EstimatedCost = KnowledgeService.FormatCurrency(mealCost, currency)
                },
                new()
                {
                    Time = "09:30",
                    Title = $"Tham quan điểm nổi bật của {destination.Name}",
                    Description = destination.Name switch
                    {
                        "Đà Lạt" =>
                            "Ưu tiên hồ Xuân Hương, vườn hoa, cà phê view đồi và các điểm chụp hình nổi bật.",

                        "Vũng Tàu" =>
                            "Ưu tiên bãi Sau, hải đăng, tượng Chúa và các quán hải sản ven biển.",

                        "Đà Nẵng" =>
                            "Ưu tiên cầu Rồng, Sơn Trà, biển Mỹ Khê và khu vực ven sông Hàn.",

                        "Hà Nội" =>
                            "Ưu tiên phố cổ, hồ Hoàn Kiếm, Văn Miếu và các trải nghiệm văn hóa.",

                        "Hội An" =>
                            "Ưu tiên phố cổ, chùa Cầu, sông Hoài và đèn lồng buổi tối.",

                        "Nha Trang" =>
                            "Ưu tiên bãi biển, các đảo gần bờ, hoạt động ngắm cảnh và tắm biển.",

                        _ =>
                            $"Ưu tiên các điểm check-in, ngắm cảnh và trải nghiệm đặc trưng của {destination.Name}."
                    },
                    Icon = "attraction",
                    EstimatedCost = KnowledgeService.FormatCurrency(activityCost, currency)
                },
                new()
                {
                    Time = "12:30",
                    Title = "Ăn trưa",
                    Description = destination.Name switch
                    {
                        "Đà Lạt" =>
                            "Ăn trưa với lẩu gà lá é, bánh ướt lòng gà hoặc các món rau đặc trưng.",

                        "Vũng Tàu" =>
                            "Ăn trưa với hải sản tươi, bánh khọt hoặc món biển địa phương.",

                        "Đà Nẵng" =>
                            "Ăn trưa với mì Quảng, bún chả cá hoặc hải sản ven biển.",

                        "Hà Nội" =>
                            "Ăn trưa với phở, bún chả, nem hoặc các quán cơm truyền thống.",

                        "Hội An" =>
                            "Ăn trưa với cao lầu, mì Quảng hoặc cơm gà Hội An.",

                        "Nha Trang" =>
                            "Ăn trưa với nem nướng, bún cá hoặc hải sản dọc biển.",

                        _ =>
                            "Chọn quán ăn có đánh giá tốt, ưu tiên món đặc sản và khẩu phần vừa tầm cho nhóm."
                    },
                    Icon = "restaurant",
                    EstimatedCost = KnowledgeService.FormatCurrency(dinnerCost, currency)
                },
                new()
                {
                    Time = "15:30",
                    Title = "Cà phê, nghỉ chân và chụp hình",
                    Description = destination.Name switch
                    {
                        "Đà Lạt" =>
                            "Dành thời gian cà phê, ghé vườn hoa hoặc chụp ảnh nhẹ trước giờ ăn tối.",

                        "Vũng Tàu" =>
                            "Nghỉ chân ở quán cà phê ven biển, đi bộ bờ biển và chụp hình hoàng hôn.",

                        "Đà Nẵng" =>
                            "Ngắm sông Hàn, ghé quán cà phê hoặc khu vui chơi nhẹ để thư giãn.",

                        "Hà Nội" =>
                            "Đi bộ phố cổ, thưởng thức cà phê trứng và dừng chân nghỉ ngơi.",

                        "Hội An" =>
                            "Đi bộ phố cổ, ngồi cà phê và chụp ảnh đèn lồng trước khi trời tối.",

                        "Nha Trang" =>
                            "Ngắm biển, tắm nắng nhẹ hoặc chọn hoạt động thư giãn ven bờ.",

                        _ =>
                            "Dành một khoảng nhẹ buổi chiều để nghỉ ngơi, ngắm view và tránh lịch quá dày."
                    },
                    Icon = "entertainment",
                    EstimatedCost = KnowledgeService.FormatCurrency(cafeCost, currency)
                },
                new()
                {
                    Time = "18:30",
                    Title = "Ăn tối và dạo chơi buổi tối",
                    Description = destination.Name switch
                    {
                        "Đà Lạt" =>
                            "Ăn tối, dạo chợ đêm và ghé thăm một quán cà phê mở cửa muộn nếu còn sức.",

                        "Vũng Tàu" =>
                            "Ăn tối với hải sản, đi dạo biển và ghé chợ đêm nếu phù hợp.",

                        "Đà Nẵng" =>
                            "Ăn tối, dạo cầu Rồng hoặc khu ven sông Hàn và chụp ảnh đêm.",

                        "Hà Nội" =>
                            "Ăn tối phố cổ, đi bộ quanh hồ Hoàn Kiếm và khám phá chợ đêm.",

                        "Hội An" =>
                            "Ăn tối phố cổ, thả đèn lồng và đi bộ ven sông Hoài.",

                        "Nha Trang" =>
                            "Ăn tối hải sản, dạo biển về đêm và nghỉ ngơi sớm.",

                        _ =>
                            $"Kết hợp ăn tối, đi bộ, tham quan khu vui chơi hoặc chợ đêm tại {destination.Name}."
                    },
                    Icon = "restaurant",
                    EstimatedCost = KnowledgeService.FormatCurrency(dinnerCost, currency)
                }
            }
        };
    }

    // ──────────────────────────────────────────────
    // HELPERS
    // ──────────────────────────────────────────────

    private static string BuildFollowUpQuestion(
        string? destinationName,
        int requestedDays,
        List<string> missingFields)
    {
        var tripLabel = !string.IsNullOrWhiteSpace(destinationName)
            ? $" cho chuyến {requestedDays} ngày tại {destinationName}"
            : string.Empty;

        return
            $"Để mình lên kế hoạch sát thực tế{tripLabel}, bạn giúp mình bổ sung: {string.Join(", ", missingFields)} nhé. " +
            "Khi có đủ thông tin, mình sẽ lên lịch trình cụ thể gồm di chuyển, khách sạn, ăn uống, điểm vui chơi và tổng chi phí dự kiến.";
    }

    private static string BuildItinerarySummaryText(ItineraryDto itinerary)
    {
        return
            $"Mình đã lên kế hoạch {itinerary.TotalDays} ngày tại {itinerary.Destination} với lịch trình cụ thể theo từng ngày. " +
            "Bạn có thể xem tổng chi phí dự kiến ở cuối kế hoạch và bấm lưu thành chuyến đi nếu thấy phù hợp.";
    }

    private static string BuildBudgetSummaryLabel(
        ItineraryCostBreakdownDto cost,
        int travelerCount,
        string? currency,
        decimal? budget)
    {
        var totalText = KnowledgeService.FormatCurrency(cost.TotalCost, currency);

        if (budget.HasValue)
        {
            var status = cost.TotalCost.HasValue && cost.TotalCost.Value <= budget.Value
                ? "sát ngân sách"
                : "cân nhắc thêm ngân sách";
            return $"Tổng dự kiến {totalText} cho {travelerCount} ngưi, {status}";
        }

        return $"Tổng dự kiến {totalText} cho {travelerCount} ngưi";
    }

    private static HotelPlanSuggestionDto? BuildHotelSuggestion(Hotel? hotel)
    {
        if (hotel == null)
        {
            return null;
        }

        var room = hotel.Rooms
            .Where(item => item.PricePerNight.HasValue)
            .OrderBy(item => item.PricePerNight)
            .FirstOrDefault();

        return new HotelPlanSuggestionDto
        {
            HotelId = hotel.Id,
            RoomId = room?.Id,
            Name = hotel.Name,
            RoomType = room?.RoomType,
            Address = hotel.Address,
            DestinationName = hotel.Destination?.Name,
            PricePerNight = room?.PricePerNight,
            Capacity = room?.Capacity,
            AvailableQty = room?.AvailableQty
        };
    }

    private static TransportPlanSuggestionDto? BuildTransportSuggestion(BusSchedule? bus)
    {
        if (bus == null)
        {
            return null;
        }

        return new TransportPlanSuggestionDto
        {
            ScheduleId = bus.Id,
            FromDestinationId = bus.FromDestId,
            FromDestinationName = bus.FromDest?.Name,
            ToDestinationId = bus.ToDestId,
            ToDestinationName = bus.ToDest?.Name,
            CompanyName = bus.Company?.Name ?? "Xe khách",
            Price = bus.Price,
            DepartureTime = bus.DepartureTime,
            ArrivalTime = bus.ArrivalTime,
            TotalSeats = bus.TotalSeats
        };
    }

    private static BusSchedule? SelectPreferredBusSchedule(
        List<BusSchedule> buses,
        string? origin,
        Destination destination)
    {
        if (buses.Count == 0)
        {
            return null;
        }

        var upcomingBuses = buses
            .Where(bus => bus.DepartureTime.HasValue
                && DateOnly.FromDateTime(bus.DepartureTime.Value.ToLocalTime()) >= DateOnly.FromDateTime(DateTime.UtcNow))
            .ToList();

        if (upcomingBuses.Count == 0)
        {
            return null;
        }

        var normalizedDestination = EntityExtractor.NormalizeText(destination.Name);
        var normalizedOrigin = string.IsNullOrWhiteSpace(origin)
            ? null
            : EntityExtractor.NormalizeText(origin);

        if (!string.IsNullOrWhiteSpace(normalizedOrigin))
        {
            var exactRoute = upcomingBuses.FirstOrDefault(bus =>
                !string.IsNullOrWhiteSpace(bus.FromDest?.Name) &&
                !string.IsNullOrWhiteSpace(bus.ToDest?.Name) &&
                IsLocationMatch(bus.FromDest!.Name!, normalizedOrigin!) &&
                IsLocationMatch(bus.ToDest!.Name!, normalizedDestination));

            return exactRoute;
        }

        return upcomingBuses.OrderBy(bus => bus.DepartureTime).FirstOrDefault(bus =>
            !string.IsNullOrWhiteSpace(bus.ToDest?.Name) &&
            IsLocationMatch(bus.ToDest!.Name!, normalizedDestination));
    }

    private static bool IsLocationMatch(string locationName, string normalizedCandidate)
    {
        var normalizedLocation = EntityExtractor.NormalizeText(locationName);
        return normalizedLocation.Contains(normalizedCandidate, StringComparison.Ordinal)
            || normalizedCandidate.Contains(normalizedLocation, StringComparison.Ordinal);
    }

    private static string BuildHotelDayDescription(Hotel hotel, int roomsNeeded)
    {
        var room = hotel.Rooms
            .Where(item => item.PricePerNight.HasValue)
            .OrderBy(item => item.PricePerNight)
            .FirstOrDefault();

        var roomType = string.IsNullOrWhiteSpace(room?.RoomType)
            ? "phòng tiêu chuẩn"
            : room!.RoomType;
        var roomCountLabel = roomsNeeded > 1 ? $"{roomsNeeded} phòng" : "1 phòng";

        return $"{roomCountLabel} {roomType}, địa chỉ {hotel.Address ?? "đang cập nhật"}, phù hợp để nghỉ trưa và di chuyển các điểm gần trung tâm.";
    }

    private static int GetEstimatedRoomCount(Hotel? hotel, int travelerCount)
    {
        var capacity = hotel == null
            ? 0
            : hotel.Rooms
                .Where(room => room.Capacity.HasValue && room.Capacity.Value > 0)
                .OrderByDescending(room => room.Capacity ?? 0)
                .Select(room => room.Capacity ?? 0)
                .FirstOrDefault();

        if (capacity <= 0)
        {
            capacity = 2;
        }

        return Math.Max(1, (int)Math.Ceiling(travelerCount / (double)capacity));
    }

    private static decimal? GetEstimatedStayCost(decimal? nightlyPrice, int days)
    {
        if (!nightlyPrice.HasValue)
        {
            return null;
        }

        var stayDays = Math.Max(1, days);
        return nightlyPrice.Value * stayDays;
    }
}


public class PlanReadiness
{
    public bool IsReady { get; set; }
    public List<string> MissingFields { get; set; } = new();
    public string? FollowUpQuestion { get; set; }

    public List<Destination> Destinations { get; set; } = new();
    public string? Origin { get; set; }
    public int? TravelerCount { get; set; }
    public decimal? Budget { get; set; }
    public string? DepartureDate { get; set; }
    public int RequestedDays { get; set; } = 3;
}

