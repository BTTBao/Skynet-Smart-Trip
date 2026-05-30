import 'package:flutter/material.dart';
import '../../models/chat_response.dart';

class WeatherBubble extends StatelessWidget {
  final WeatherInfo weather;

  const WeatherBubble({super.key, required this.weather});

  IconData _getWeatherIcon(String? iconName) {
    switch (iconName) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'partly_cloudy':
        return Icons.cloud;
      case 'cloudy':
        return Icons.cloud_queue;
      case 'rainy':
        return Icons.umbrella;
      case 'stormy':
        return Icons.thunderstorm;
      case 'snowy':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String? iconName) {
    switch (iconName) {
      case 'sunny':
        return const Color(0xFFFF9800);
      case 'partly_cloudy':
        return const Color(0xFF42A5F5);
      case 'rainy':
        return const Color(0xFF5C6BC0);
      case 'stormy':
        return const Color(0xFF37474F);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = _getWeatherColor(weather.icon);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Main weather
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainColor, mainColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(_getWeatherIcon(weather.icon), size: 48, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (weather.temperature != null)
                          Text(
                            '${weather.temperature!.toStringAsFixed(0)}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        if (weather.condition != null)
                          Text(
                            weather.condition!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Extra info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (weather.humidity != null)
                        _buildSmallInfo(Icons.water_drop, '${weather.humidity}%'),
                      const SizedBox(height: 6),
                      if (weather.windSpeed != null)
                        _buildSmallInfo(Icons.air, '${weather.windSpeed!.toStringAsFixed(0)} km/h'),
                    ],
                  ),
                ],
              ),
            ),
            // Forecast
            if (weather.forecast != null && weather.forecast!.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weather.forecast!.map((day) {
                    return Column(
                      children: [
                        Text(
                          day.day,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Icon(_getWeatherIcon(day.icon), size: 20, color: _getWeatherColor(day.icon)),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 11),
                            children: [
                              TextSpan(
                                text: '${day.tempHigh?.toStringAsFixed(0) ?? "-"}°',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              TextSpan(
                                text: ' / ${day.tempLow?.toStringAsFixed(0) ?? "-"}°',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            // Travel advice
            if (weather.travelAdvice != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates, size: 16, color: Color(0xFF80ed99)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weather.travelAdvice!,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
      ],
    );
  }
}
