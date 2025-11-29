import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MealCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const MealCard({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: imageUrl.isEmpty
                ? Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildErrorWidget(imageUrl);
                        },
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            calories.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Calories",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            protein.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Protein",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            carbs.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Carbs",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            fats.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Fats",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String imageUrl) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'Image unavailable',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'CORS or Storage Rules issue\nCheck Firebase Console',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Text(
                'Check console for details',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
