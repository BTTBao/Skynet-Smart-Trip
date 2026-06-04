import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../models/create_fake_payment_request.dart';
import '../../models/create_hotel_booking_request.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../models/create_trip_request.dart';
import '../../models/my_trip_summary.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/catalog_service.dart';
import '../../utils/app_currency_formatter.dart';

class HotelDetailView extends StatefulWidget {
  const HotelDetailView({super.key, required this.hotelId});

  final int hotelId;

  @override
  State<HotelDetailView> createState() => _HotelDetailViewState();
}

class _HotelDetailViewState extends State<HotelDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadHotelDetail(widget.hotelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Consumer<CatalogProvider>(
        builder: (context, provider, _) {
          final detail = provider.selectedHotel;

          if (provider.isLoadingHotelDetail && detail == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (detail == null) {
            return Center(
              child: Text(
                provider.error ?? 'Không tải được chi tiết khách sạn.',
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _GalleryHeader(detail: detail),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFBBF24),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${detail.rating.toStringAsFixed(1)} • ${detail.reviewCount} đánh giá',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  detail.address.isEmpty
                                      ? '${detail.destinationName}, Việt Nam'
                                      : detail.address,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Mô tả',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            detail.description,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: AppColors.textBody,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Tiện ích',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: detail.amenities
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.borderDefault,
                                      ),
                                    ),
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Hạng phòng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...detail.rooms.map((room) => _RoomCard(room: room)),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Đánh giá',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${detail.reviewCount} nhận xét',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...detail.reviews
                              .take(4)
                              .map((review) => _ReviewCard(review: review)),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Giá từ',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppCurrencyFormatter.format(detail.pricePerNight)} / đêm',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _openBookingSheetSmart(detail),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Đặt ngay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openBookingSheet(CatalogHotelDetail detail) async {
    final availableRooms = detail.rooms
        .where((room) => room.availableQty > 0)
        .toList(growable: false);

    if (availableRooms.isEmpty) {
      _showMessage('Khách sạn hiện không còn phòng trống.');
      return;
    }

    final now = DateTime.now();
    var checkIn = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    var checkOut = checkIn.add(const Duration(days: 1));
    var selectedRoom = availableRooms.first;
    var roomQuantity = 1;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final nights = _nightsBetween(checkIn, checkOut);
            final totalPrice = selectedRoom.pricePerNight * nights * roomQuantity;

            Future<void> pickDate({required bool isCheckIn}) async {
              final today = DateTime(now.year, now.month, now.day);
              final picked = await showDatePicker(
                context: context,
                initialDate: isCheckIn ? checkIn : checkOut,
                firstDate: today,
                lastDate: today.add(const Duration(days: 365)),
              );

              if (picked == null) {
                return;
              }

              setSheetState(() {
                if (isCheckIn) {
                  checkIn = DateTime(picked.year, picked.month, picked.day);
                  if (!checkOut.isAfter(checkIn)) {
                    checkOut = checkIn.add(const Duration(days: 1));
                  }
                } else {
                  final normalized = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                  if (normalized.isAfter(checkIn)) {
                    checkOut = normalized;
                  }
                }
              });
            }

            Future<void> submitBooking() async {
              if (!checkOut.isAfter(checkIn)) {
                _showMessage('Ngày trả phòng phải sau ngày nhận phòng.');
                return;
              }

              if (roomQuantity > selectedRoom.availableQty) {
                _showMessage('Số phòng đặt vượt quá số phòng còn trống.');
                return;
              }

              setSheetState(() => isSubmitting = true);
              final tripProvider = context.read<TripProvider>();
              final createdTrip = await tripProvider.createHotelBooking(
                CreateHotelBookingRequest(
                  userId: 1,
                  hotelId: detail.id,
                  roomId: selectedRoom.id,
                  destinationId: detail.destinationId,
                  destinationName: detail.destinationName,
                  title: 'Đặt phòng - ${detail.name}',
                  checkInDate: checkIn,
                  checkOutDate: checkOut,
                  quantity: roomQuantity,
                  adultCount: roomQuantity,
                ),
              );

              if (createdTrip == null) {
                setSheetState(() => isSubmitting = false);
                _showMessage(
                  tripProvider.error ?? 'Không thể tạo đơn đặt phòng.',
                );
                return;
              }

              if (!mounted || !sheetContext.mounted) {
                return;
              }

              setSheetState(() => isSubmitting = false);
              Navigator.of(sheetContext).pop();
              await _openFakePaymentSheet(
                tripId: createdTrip.tripId,
                hotelName: detail.name,
                roomType: selectedRoom.roomType,
                amount: totalPrice,
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      detail.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BookingDateTile(
                            label: 'Nhận phòng',
                            value: _formatDate(checkIn),
                            onTap: () => pickDate(isCheckIn: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BookingDateTile(
                            label: 'Trả phòng',
                            value: _formatDate(checkOut),
                            onTap: () => pickDate(isCheckIn: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedRoom.id,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(18),
                          items: availableRooms.map((room) {
                            return DropdownMenuItem<int>(
                              value: room.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    room.roomType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                  Text(
                                    '${room.capacity} người • ${room.availableQty} phòng • ${AppCurrencyFormatter.format(room.pricePerNight)}/đêm',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isSubmitting
                              ? null
                              : (roomId) {
                                  if (roomId == null) {
                                    return;
                                  }

                                  final room = availableRooms.firstWhere(
                                    (item) => item.id == roomId,
                                  );
                                  setSheetState(() {
                                    selectedRoom = room;
                                    if (roomQuantity > selectedRoom.availableQty) {
                                      roomQuantity = selectedRoom.availableQty;
                                    }
                                  });
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Số phòng',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: roomQuantity <= 1
                                ? null
                                : () => setSheetState(() => roomQuantity--),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Text(
                            '$roomQuantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: roomQuantity >= selectedRoom.availableQty
                                ? null
                                : () => setSheetState(() => roomQuantity++),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$nights đêm • ${selectedRoom.capacity} người/phòng • Còn ${selectedRoom.availableQty} phòng',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng tiền',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        Text(
                          AppCurrencyFormatter.format(totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submitBooking,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text(
                                'Xác nhận đặt phòng',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openBookingSheetSmart(CatalogHotelDetail detail) async {
    final availableRooms = detail.rooms
        .where((room) => room.availableQty > 0)
        .toList(growable: false);
    final catalogService = CatalogService();

    if (availableRooms.isEmpty) {
      _showMessage('Khách sạn hiện không còn phòng trống.');
      return;
    }

    final now = DateTime.now();
    var checkIn = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    var checkOut = checkIn.add(const Duration(days: 1));
    var selectedRoom = availableRooms.first;
    var roomQuantity = 1;
    var isSubmitting = false;
    var isCheckingAvailability = false;
    var availabilityRequestVersion = 0;

    CatalogRoomAvailability availability = await catalogService
        .getRoomAvailability(
          roomId: selectedRoom.id,
          checkInDate: checkIn,
          checkOutDate: checkOut,
          quantity: roomQuantity,
        )
        .catchError(
          (_) => CatalogRoomAvailability(
            roomId: selectedRoom.id,
            totalQty: selectedRoom.availableQty,
            remainingQty: selectedRoom.availableQty,
            isAvailable: selectedRoom.availableQty > 0,
            message: selectedRoom.availableQty > 0
                ? 'Còn ${selectedRoom.availableQty} phòng có thể đặt.'
                : 'Đã có người đặt hết.',
          ),
        );

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final nights = _nightsBetween(checkIn, checkOut);
            final totalPrice =
                selectedRoom.pricePerNight * nights * roomQuantity;

            Future<CatalogRoomAvailability?> refreshAvailability() async {
              final requestVersion = ++availabilityRequestVersion;
              setSheetState(() => isCheckingAvailability = true);

              try {
                final result = await catalogService.getRoomAvailability(
                  roomId: selectedRoom.id,
                  checkInDate: checkIn,
                  checkOutDate: checkOut,
                  quantity: roomQuantity,
                );

                if (!sheetContext.mounted) {
                  return null;
                }

                if (requestVersion != availabilityRequestVersion) {
                  return null;
                }

                setSheetState(() {
                  availability = result;
                  if (availability.remainingQty > 0 &&
                      roomQuantity > availability.remainingQty) {
                    roomQuantity = availability.remainingQty;
                  }
                });
                return result;
              } catch (_) {
                if (!sheetContext.mounted) {
                  return null;
                }

                if (requestVersion != availabilityRequestVersion) {
                  return null;
                }

                setSheetState(() {
                  availability = CatalogRoomAvailability(
                    roomId: selectedRoom.id,
                    totalQty: selectedRoom.availableQty,
                    remainingQty: 0,
                    isAvailable: false,
                    message: 'Không thể kiểm tra tình trạng phòng lúc này.',
                  );
                });
              } finally {
                if (sheetContext.mounted &&
                    requestVersion == availabilityRequestVersion) {
                  setSheetState(() => isCheckingAvailability = false);
                }
              }

              return null;
            }

            Future<void> pickDate({required bool isCheckIn}) async {
              final today = DateTime(now.year, now.month, now.day);
              final picked = await showDatePicker(
                context: context,
                initialDate: isCheckIn ? checkIn : checkOut,
                firstDate: today,
                lastDate: today.add(const Duration(days: 365)),
              );

              if (picked == null) {
                return;
              }

              setSheetState(() {
                if (isCheckIn) {
                  checkIn = DateTime(picked.year, picked.month, picked.day);
                  if (!checkOut.isAfter(checkIn)) {
                    checkOut = checkIn.add(const Duration(days: 1));
                  }
                } else {
                  final normalized = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                  if (normalized.isAfter(checkIn)) {
                    checkOut = normalized;
                  }
                }
              });

              await refreshAvailability();
            }

            Future<void> submitBooking() async {
              if (!checkOut.isAfter(checkIn)) {
                _showMessage('Ngày trả phòng phải sau ngày nhận phòng.');
                return;
              }

              final latestAvailability = await refreshAvailability();
              final checkedAvailability = latestAvailability ?? availability;

              if (checkedAvailability.remainingQty <= 0 ||
                  roomQuantity > checkedAvailability.remainingQty) {
                _showMessage(checkedAvailability.message);
                return;
              }

              final tripProvider = context.read<TripProvider>();
              final selectedTrip = await _selectOrCreateTripForBooking(
                detail: detail,
                checkIn: checkIn,
                checkOut: checkOut,
              );

              if (selectedTrip == null) {
                return;
              }

              if (!sheetContext.mounted) {
                return;
              }

              setSheetState(() => isSubmitting = true);
              final itineraryAdded = await tripProvider.addItinerary(
                selectedTrip.tripId,
                CreateTripItineraryRequest(
                  dayNumber: selectedTrip.dayNumber,
                  serviceType: 'HOTEL',
                  serviceId: selectedRoom.id,
                  quantity: roomQuantity,
                  adultCount: roomQuantity,
                  bookedPrice: selectedRoom.pricePerNight * nights,
                  serviceDate: checkIn,
                ),
              );

              if (!itineraryAdded) {
                if (sheetContext.mounted) {
                  setSheetState(() => isSubmitting = false);
                }
                _showMessage(
                  tripProvider.error ?? 'Không thể thêm phòng vào chuyến đi.',
                );
                return;
              }

              if (!mounted || !sheetContext.mounted) {
                return;
              }

              setSheetState(() => isSubmitting = false);
              Navigator.of(sheetContext).pop();

              await _openFakePaymentSheet(
                tripId: selectedTrip.tripId,
                hotelName: detail.name,
                roomType: selectedRoom.roomType,
                amount: totalPrice,
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      detail.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BookingDateTile(
                            label: 'Nhận phòng',
                            value: _formatDate(checkIn),
                            onTap: () => pickDate(isCheckIn: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BookingDateTile(
                            label: 'Trả phòng',
                            value: _formatDate(checkOut),
                            onTap: () => pickDate(isCheckIn: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedRoom.id,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(18),
                          items: availableRooms.map((room) {
                            return DropdownMenuItem<int>(
                              value: room.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    room.roomType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                  Text(
                                    '${room.capacity} người • Tối đa ${room.availableQty} phòng • ${AppCurrencyFormatter.format(room.pricePerNight)}/đêm',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isSubmitting
                              ? null
                              : (roomId) async {
                                  if (roomId == null) {
                                    return;
                                  }

                                  final room = availableRooms.firstWhere(
                                    (item) => item.id == roomId,
                                  );
                                  setSheetState(() {
                                    selectedRoom = room;
                                    if (roomQuantity > room.availableQty) {
                                      roomQuantity = room.availableQty;
                                    }
                                  });
                                  await refreshAvailability();
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Số phòng',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: roomQuantity <= 1
                                ? null
                                : () async {
                                    setSheetState(() => roomQuantity--);
                                    await refreshAvailability();
                                  },
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Text(
                            '$roomQuantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: roomQuantity >= availability.remainingQty
                                ? null
                                : () async {
                                    setSheetState(() => roomQuantity++);
                                    await refreshAvailability();
                                  },
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isCheckingAvailability
                          ? '$nights đêm • ${selectedRoom.capacity} người/phòng • Đang tính số phòng còn lại...'
                          : '$nights đêm • ${selectedRoom.capacity} người/phòng • Còn ${availability.remainingQty}/${availability.totalQty} phòng cho ngày đã chọn',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    if (!isCheckingAvailability) ...[
                      const SizedBox(height: 6),
                      Text(
                        availability.message,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng tiền',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        Text(
                          AppCurrencyFormatter.format(totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting ||
                                isCheckingAvailability ||
                                availability.remainingQty <= 0 ||
                                roomQuantity > availability.remainingQty
                            ? null
                            : submitBooking,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : Text(
                                isCheckingAvailability
                                    ? 'Đang kiểm tra phòng'
                                    : availability.remainingQty <= 0
                                        ? 'Đã có người đặt'
                                        : roomQuantity <= availability.remainingQty
                                            ? 'Xác nhận đặt phòng'
                                            : 'Chỉ còn ${availability.remainingQty} phòng',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openFakePaymentSheet({
    required int tripId,
    required String hotelName,
    required String roomType,
    required double amount,
  }) async {
    var paymentMethod = 'Momo';
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitPayment() async {
              setSheetState(() => isSubmitting = true);

              if (tripId == 0) {
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted || !sheetContext.mounted) {
                  return;
                }
                setSheetState(() => isSubmitting = false);
                Navigator.of(sheetContext).pop();
                _showMessage('Thanh toán thành công. Đơn đặt phòng đã được ghi nhận.');
                return;
              }

              final tripProvider = context.read<TripProvider>();
              final paidTrip = await tripProvider.completeFakePayment(
                tripId,
                CreateFakePaymentRequest(
                  paymentMethod: paymentMethod,
                  amount: amount,
                ),
              );

              if (!mounted || !sheetContext.mounted) {
                return;
              }

              setSheetState(() => isSubmitting = false);

              if (paidTrip == null) {
                _showMessage(
                  tripProvider.error ?? 'Thanh toán thử nghiệm thất bại.',
                );
                return;
              }

              Navigator.of(sheetContext).pop();
              await context.read<CatalogProvider>().loadHotelDetail(widget.hotelId);
              _showMessage('Thanh toán thành công. Đơn đặt phòng đã được ghi nhận.');
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Thanh toán thử nghiệm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$hotelName • $roomType',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Số tiền cần thanh toán',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          Text(
                            AppCurrencyFormatter.format(amount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PaymentMethodChip(
                          label: 'Momo',
                          selected: paymentMethod == 'Momo',
                          onTap: () => setSheetState(() => paymentMethod = 'Momo'),
                        ),
                        _PaymentMethodChip(
                          label: 'VNPay',
                          selected: paymentMethod == 'Vnpay',
                          onTap: () => setSheetState(() => paymentMethod = 'Vnpay'),
                        ),
                        _PaymentMethodChip(
                          label: 'Thẻ',
                          selected: paymentMethod == 'Card',
                          onTap: () => setSheetState(() => paymentMethod = 'Card'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submitPayment,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text(
                                'Thanh toán ngay',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<_SelectedBookingTrip?> _selectOrCreateTripForBooking({
    required CatalogHotelDetail detail,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final tripProvider = context.read<TripProvider>();
    await tripProvider.fetchTrips(silent: true);

    if (!mounted) {
      return null;
    }

    final upcomingBookingTrips = tripProvider.upcomingTrips
        .where((trip) => trip.status != 'CANCELLED')
        .toList(growable: false)
      ..sort((left, right) => left.startDate.compareTo(right.startDate));

    return showModalBottomSheet<_SelectedBookingTrip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var isCreating = false;
        var title = 'Chuyến đi ${detail.destinationName}';
        var tripQuery = '';

        Future<void> createTrip(StateSetter setSheetState) async {
          final normalizedTitle = title.trim();
          if (normalizedTitle.isEmpty) {
            _showMessage('Vui lòng nhập tên chuyến đi.');
            return;
          }

          setSheetState(() => isCreating = true);
          final profile = context.read<ProfileProvider>().profileData;
          final userId = int.tryParse(profile?.id ?? '') ?? 1;
          final createdTrip = await tripProvider.createTrip(
            CreateTripRequest(
              userId: userId,
              destinationId: detail.destinationId,
              destinationName: detail.destinationName,
              title: normalizedTitle,
              startDate: checkIn,
              endDate: checkOut,
              status: 'PENDING',
            ),
          );

          if (!sheetContext.mounted) {
            return;
          }

          setSheetState(() => isCreating = false);
          if (createdTrip == null) {
            _showMessage(tripProvider.error ?? 'Không thể tạo chuyến đi.');
            return;
          }

          Navigator.of(sheetContext).pop(
            _SelectedBookingTrip(tripId: createdTrip.tripId, dayNumber: 1),
          );
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final normalizedQuery = tripQuery.trim().toLowerCase();
            final visibleTrips = normalizedQuery.isEmpty
                ? upcomingBookingTrips
                : upcomingBookingTrips
                    .where(
                      (trip) =>
                          trip.title.toLowerCase().contains(normalizedQuery) ||
                          trip.destination
                              .toLowerCase()
                              .contains(normalizedQuery) ||
                          trip.dateRange.toLowerCase().contains(normalizedQuery),
                    )
                    .toList(growable: false);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Thêm vào chuyến đi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phòng đã đặt sẽ nằm trong lịch trình chuyến đi của bạn. Chuyến đi cần cùng điểm đến và bao trọn ngày nhận/trả phòng.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      enabled: !isCreating,
                      onChanged: (value) =>
                          setSheetState(() => tripQuery = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        labelText: 'Tìm chuyến đi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (visibleTrips.isNotEmpty) ...[
                      ...visibleTrips.map(
                        (trip) {
                          final blockedReason = _bookingTripBlockReason(
                            trip: trip,
                            detail: detail,
                            checkIn: checkIn,
                            checkOut: checkOut,
                          );
                          final canSelect = blockedReason == null;

                          return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: isCreating || !canSelect
                                ? null
                                : () {
                                    Navigator.of(sheetContext).pop(
                                      _SelectedBookingTrip(
                                        tripId: trip.tripId,
                                        dayNumber:
                                            _dayNumberForTrip(trip, checkIn),
                                      ),
                                    );
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: canSelect
                                    ? Colors.white
                                    : const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: AppColors.borderDefault,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.map_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textHeading,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${trip.destination} • ${trip.dateRange}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        if (blockedReason != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            blockedReason,
                                            style: const TextStyle(
                                              color: Color(0xFFB42318),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    canSelect
                                        ? Icons.chevron_right_rounded
                                        : Icons.lock_outline_rounded,
                                    color: canSelect
                                        ? AppColors.textHeading
                                        : AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        },
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: const Text(
                          'Không tìm thấy chuyến đi phù hợp. Hãy tạo chuyến đi mới để tiếp tục đặt phòng.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      enabled: !isCreating,
                      controller: TextEditingController(text: title)
                        ..selection = TextSelection.collapsed(
                          offset: title.length,
                        ),
                      onChanged: (value) => title = value,
                      decoration: InputDecoration(
                        labelText: 'Tên chuyến đi mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            isCreating ? null : () => createTrip(setSheetState),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isCreating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text(
                                'Tạo chuyến đi mới',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _nightsBetween(DateTime checkIn, DateTime checkOut) {
    return checkOut.difference(checkIn).inDays.clamp(1, 365);
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  int _dayNumberForTrip(MyTripSummary trip, DateTime checkIn) {
    return _dateOnly(checkIn).difference(_dateOnly(trip.startDate)).inDays + 1;
  }

  String? _bookingTripBlockReason({
    required MyTripSummary trip,
    required CatalogHotelDetail detail,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    if (trip.destinationId != detail.destinationId) {
      return 'Khac diem den voi khach san nay.';
    }

    final tripStart = _dateOnly(trip.startDate);
    final tripEnd = _dateOnly(trip.endDate);
    final bookingStart = _dateOnly(checkIn);
    final bookingEnd = _dateOnly(checkOut);

    if (tripStart.isAfter(bookingStart) || tripEnd.isBefore(bookingEnd)) {
      return 'Ngay di phai bao tron ngay nhan/tra phong.';
    }

    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SelectedBookingTrip {
  const _SelectedBookingTrip({required this.tripId, required this.dayNumber});

  final int tripId;
  final int dayNumber;
}

class _GalleryHeader extends StatefulWidget {
  const _GalleryHeader({required this.detail});

  final CatalogHotelDetail detail;

  @override
  State<_GalleryHeader> createState() => _GalleryHeaderState();
}

class _GalleryHeaderState extends State<_GalleryHeader> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.detail.imageUrls.length,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemBuilder: (context, index) => Image.network(
              widget.detail.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFFE2E8F0)),
            ),
          ),
          Positioned(
            top: 18,
            left: 16,
            child: _RoundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const Positioned(
            top: 18,
            right: 16,
            child: _RoundButton(icon: Icons.share_outlined),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFF43F5E),
                size: 28,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.detail.imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final CatalogRoomOption room;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.roomType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sức chứa ${room.capacity} người • Tối đa ${room.availableQty} phòng',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppCurrencyFormatter.format(room.pricePerNight),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final CatalogReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE2E8F0),
                child: Text(
                  review.userName.isEmpty
                      ? 'K'
                      : review.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textHeading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      review.createdAt == null
                          ? 'Gần đây'
                          : '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  review.rating,
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(color: AppColors.textBody, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _BookingDateTile extends StatelessWidget {
  const _BookingDateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9FFF0) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF166534) : AppColors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
