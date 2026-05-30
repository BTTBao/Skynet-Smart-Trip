import 'package:flutter/material.dart';

class ResortLocationMap extends StatelessWidget {
  const ResortLocationMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vị trí',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Mở trong Maps',
                  style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Placeholder for actual Google Maps Integration
                   Image.network(
                      'https://maps.googleapis.com/maps/api/staticmap?center=Da+Lat&zoom=13&size=600x300&maptype=roadmap&key=YOUR_API_KEY',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('Map View Placeholder')),
                   ),
                  const Icon(Icons.location_on, color: Colors.green, size: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
