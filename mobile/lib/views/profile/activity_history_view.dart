import 'package:flutter/material.dart';

class ActivityHistoryView extends StatelessWidget {
  const ActivityHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFec5b13);
    const secondaryGreenColor = Color(0xFF80ed99);
    
    // Sample data to mimic the HTML items
    final List<Map<String, String>> activities = [
      {
        'title': 'Tour lặn ngắm san hô Phú Quốc',
        'date': '10/10/2023',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDg66zuV2pCtT64lrAjmeDKytvqC_ZiIFdvo1Qjbdy46N3m59cxyr14H3QX_KXB10x8p_6AWNtjD-iyp_okCxkuKCiaa0UX9d59kdzI19gUO_17Jy-tzoRvVPuNXruTtlB8jkFpIxXv76w9H8TtEJtHe_c06jQjhM5euj1KzUO0t7pFMIHMPTbdvro9YDNtDn9FRhc0cjs7zEK4GLqD5UM5o704oTJV-oBsox1WaOXmrskjsd2K9tDpYKNAMUFXUH0WXLRYC9lv84lY'
      },
      {
        'title': 'Vé cáp treo Bà Nà Hills',
        'date': '05/10/2023',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBXa3JyCc1Z-zfQUTe80MIwwHfHs98cDP5Eaj0zT1pMAPeZVtg8_wrL6zJBNYVOkazQocPZmjQVMhCdabQ9mF-UCz71PCX9XEeQzeU0RVd1RcdKT-NK8GxvexgqIbSzwHC0IkwcssCU4Q-RrC0W-0vtN925Ylecz4bX2BtUqe5oajqEcl3TmjYS4_wtq-EDBnXHolDoNbclgwoO9GAo2a6GVIN2k1wToVSgIm44y9XUvWW2U2ytGmQXjp7VMp6w3mpSaQ4H447NvLoc'
      },
      {
        'title': 'Khách sạn Pullman Vũng Tàu',
        'date': '20/09/2023',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBmcD-2M3sZ9bFocZUJIf2e_ATdUKrdh3_9DbuGbV-DrKwzod4cf47cLCFGW7KU2pTb1nK-pa1068rFZ9Lstxyd-lMYrHwGBYHk9CtlJF6NYNjtd6lo0pw3FN5c05Izz8BVu3J_SFkYxOy-7QYJbatE4R3Kp-DVsA5S1XcBWcIsAlNSdoEyCCXysat3zQ3OdK6F3rPIImYSOrUDeUMrpjcH1OlNdIMZERLoJOpZlHJGOzMQ-Cu1tXQBSfNkIKhDtFojiWI8xDIrm7_r'
      },
      {
        'title': 'Du thuyền Heritage Hạ Long',
        'date': '15/09/2023',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDdpyqUiEDBpqGxFjyyuXFVWT83POi-vY1z9_1jUkmN_63fjrJRIt5WuAgvT8uwO0G5Aia-NdP9q1kFBykwqx5PqvUQY3soVyhR9mxSyYluT3_I8uUKOpc3jSMjRljgAq__8aD-TzMXiG1ZKWMHgInGKUkonvF0lu6QP9Uza_PWgr1gz5-LpTx_ZdyijbjzqIbjuIrGA-1VoQ1Us3zyqY97jNexlK6MIDdF5cHzH8HkdWSRZSJWRcXXBDCjLFN3fTY80Hoq4wrElAY3'
      },
      {
        'title': 'Hanoi Street Food Tour',
        'date': '02/09/2023',
        'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB04rX8A4czEtMRoZMpzf68G949XCHf9pdmFmSe44D8HK7fDWPpZoEKJivG57eyewEoa6jkSm2Z2ID8dZIlpm2JQ5Dsmnd5iBjCiu6NYAXdFvpN-Ma6KpLO5dHR53PcTETfVirkh4QXdNvaHsS9CmZD2HeTTBqrj3gPfZWY9b6xTNn63vdMr_dTjtHCvH2ERQpdfkw6ihiFqIyFWqkWoouCHHC1001_2Hnf_V6v4uyLQ7_4Y8knNms_qzZv4Wp2AHG8ckvy1mKuxclJ'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: const CircleBorder(),
            ),
          ),
        ),
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade100,
          height: 32,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final item = activities[index];
          return _buildActivityItem(
            title: item['title']!,
            date: item['date']!,
            imageUrl: item['image']!,
            buttonColor: secondaryGreenColor,
          );
        },
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String date,
    required String imageUrl,
    required Color buttonColor,
  }) {
    return Row(
      children: [
        // Image thumbnail
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        
        // Rebook Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Đặt lại',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
