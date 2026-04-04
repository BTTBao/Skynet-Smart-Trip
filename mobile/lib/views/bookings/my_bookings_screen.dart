import 'package:flutter/material.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chuyến đi của tôi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green[500],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.green[400],
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Sắp tới'),
                Tab(text: 'Đã hoàn thành'),
                Tab(text: 'Đã hủy'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          const Center(child: Text('Danh sách đã hoàn thành trống')),
          const Center(child: Text('Danh sách đã hủy trống')),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          category: 'PHÒNG DELUXE',
          status: 'Đã xác nhận',
          statusColor: Colors.green[100]!,
          statusTextColor: Colors.green[700]!,
          title: 'Resort Sun Valley',
          dateInfo: 'Check-in: 20/10/2023',
          imageUrl: 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
          btn1Text: 'Xem vé',
          btn1Icon: Icons.airplane_ticket,
          btn1Color: Colors.green[300]!,
          btn1Action: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingDetailScreen()));
          },
          btn2Text: 'Chi tiết',
          btn2Icon: Icons.info_outline,
          isBtn2Outlined: true,
        ),
        const SizedBox(height: 16),
        _buildBookingCard(
          category: 'PHÒNG SUITE',
          status: 'Chờ xác nhận',
          statusColor: Colors.orange[100]!,
          statusTextColor: Colors.orange[800]!,
          title: 'Khách sạn Mường Thanh',
          dateInfo: 'Check-in: 25/10/2023',
          imageUrl: 'https://images.unsplash.com/photo-1542314831-c6a4d14d837e?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
          btn1Text: 'Xem vé',
          btn1Icon: Icons.airplane_ticket,
          btn1Color: Colors.green[300]!,
          btn2Text: 'Đổi lịch',
          btn2Icon: Icons.edit_calendar,
          isBtn2Outlined: true,
        ),
        const SizedBox(height: 16),
        _buildBookingCard(
          category: 'TOUR TRONG NGÀY',
          status: 'Đã xác nhận',
          statusColor: Colors.green[100]!,
          statusTextColor: Colors.green[700]!,
          title: 'Khám phá Vịnh Hạ Long',
          dateInfo: 'Khởi hành: 28/10/2023',
          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Halong_Bay_Vietnam.jpg/800px-Halong_Bay_Vietnam.jpg',
          btn1Text: 'Xem vé',
          btn1Icon: Icons.airplane_ticket,
          btn1Color: Colors.green[300]!,
          btn2Text: 'Bản đồ',
          btn2Icon: Icons.map,
          isBtn2Outlined: true,
        ),
      ],
    );
  }

  Widget _buildBookingCard({
    required String category,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String title,
    required String dateInfo,
    required String imageUrl,
    required String btn1Text,
    required IconData btn1Icon,
    required Color btn1Color,
    VoidCallback? btn1Action,
    required String btn2Text,
    required IconData btn2Icon,
    bool isBtn2Outlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(status, style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(dateInfo, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: btn1Action ?? () {},
                  icon: Icon(btn1Icon, color: Colors.black, size: 18),
                  label: Text(btn1Text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btn1Color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isBtn2Outlined
                    ? OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(btn2Icon, color: const Color(0xFF1E293B), size: 18),
                        label: Text(btn2Text, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(btn2Icon, color: Colors.black, size: 18),
                        label: Text(btn2Text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
              )
            ],
          )
        ],
      ),
    );
  }
}
