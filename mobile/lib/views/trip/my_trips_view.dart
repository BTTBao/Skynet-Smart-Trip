import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/my_trip_summary.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip/widgets.dart';
import 'create_trip_view.dart';
import 'trip_itinerary_detail_view.dart';
import 'trip_ui_constants.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips();
    });
  }

  void _openCreateTrip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateTripView()),
    );
  }

  void _openTripDetail(MyTripSummary trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: trip.tripId,
          tripTitle: trip.title,
          startDate: trip.startDate,
          endDate: trip.endDate,
          travelerInitial: trip.title.isEmpty ? 'T' : trip.title[0].toUpperCase(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final visibleTrips = _selectedTabIndex == 0
            ? tripProvider.upcomingTrips
            : tripProvider.completedTrips;

        return Scaffold(
          backgroundColor: TripUiColors.background,
          floatingActionButton: MyTripsFab(
            onTap: _openCreateTrip,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => tripProvider.fetchTrips(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      'Chuyen di cua toi',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: TripUiColors.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kham pha va quan ly nhung hanh trinh tuyet voi cua ban.',
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
                    if (tripProvider.isLoadingTrips && tripProvider.trips.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (tripProvider.error != null && tripProvider.trips.isEmpty)
                      _TripStateCard(
                        title: 'Khong tai duoc danh sach chuyen di',
                        subtitle: tripProvider.error!,
                        actionLabel: 'Thu lai',
                        onTap: () => tripProvider.fetchTrips(),
                      )
                    else if (visibleTrips.isEmpty)
                      _TripStateCard(
                        title: _selectedTabIndex == 0
                            ? 'Chua co chuyen di sap toi'
                            : 'Chua co chuyen di da hoan thanh',
                        subtitle: _selectedTabIndex == 0
                            ? 'Tao chuyen di moi de bat dau len lich trinh.'
                            : 'Nhung chuyen di da qua se xuat hien o day.',
                        actionLabel: 'Tao chuyen di',
                        onTap: _openCreateTrip,
                      )
                    else
                      ...visibleTrips.map((trip) {
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
          ),
        );
      },
    );
  }
}

class _TripStateCard extends StatelessWidget {
  const _TripStateCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.route_outlined,
            size: 40,
            color: TripUiColors.timelineGreen,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TripUiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: TripUiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: TripUiColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
