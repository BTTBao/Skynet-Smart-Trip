import 'package:flutter/material.dart';

import '../../models/my_trip_summary.dart';
import '../../widgets/trip/widgets.dart';
import 'create_trip_view.dart';
import 'my_trips_view_data.dart';
import 'trip_itinerary_detail_view.dart';
import 'trip_ui_constants.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  int _selectedTabIndex = 0;

  List<MyTripSummary> get _visibleTrips =>
      _selectedTabIndex == 0 ? upcomingTrips : completedTrips;

  void _openCreateTrip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateTripView()),
    );
  }

  void _openTripDetail(MyTripSummary trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripTitle: trip.title,
          startDate: trip.startDate,
          endDate: trip.endDate,
          travelerInitial: trip.title[0].toUpperCase(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripUiColors.background,
      floatingActionButton: MyTripsFab(
        onTap: _openCreateTrip,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FFF0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: TripUiColors.timelineGreen,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFB7F5C6), Color(0xFF1FB266)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Chuyến đi của tôi',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: TripUiColors.textPrimary,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khám phá và quản lý những hành trình tuyệt vời của bạn.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: TripUiColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              MyTripFilterTabs(
                selectedIndex: _selectedTabIndex,
                onSelected: (value) => setState(() => _selectedTabIndex = value),
              ),
              const SizedBox(height: 18),
              ..._visibleTrips.map((trip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: MyTripCard(
                    trip: trip,
                    onTap: () => _openTripDetail(trip),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
