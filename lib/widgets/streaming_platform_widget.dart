import 'package:flutter/material.dart';
import '../models/streaming_platform.dart';
import '../models/movie.dart';

/// Widget to display streaming platform logos
class StreamingPlatformLogo extends StatelessWidget {
  final StreamingPlatform platform;
  final double size;
  final bool showName;

  const StreamingPlatformLogo({
    super.key,
    required this.platform,
    this.size = 40,
    this.showName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildPlatformLogo(),
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 4),
          Text(
            platform.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildPlatformLogo() {
    // For now, we'll use colored containers with platform initials
    // In a real app, you'd have actual logo images
    return Container(
      color: _getPlatformColor(),
      child: Center(
        child: Text(
          _getPlatformInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getPlatformColor() {
    switch (platform.id) {
      case 'netflix':
        return const Color(0xFFE50914);
      case 'disney_plus':
        return const Color(0xFF0063E5);
      case 'amazon_prime':
        return const Color(0xFF00A8E1);
      case 'hulu':
        return const Color(0xFF1CE783);
      case 'hbo_max':
        return const Color(0xFF5F2EEA);
      case 'apple_tv':
        return Colors.black;
      case 'paramount_plus':
        return const Color(0xFF0066CC);
      case 'peacock':
        return const Color(0xFF000000);
      case 'youtube_tv':
        return const Color(0xFFFF0000);
      case 'tubi':
        return const Color(0xFF7B68EE);
      case 'pluto_tv':
        return const Color(0xFFE50914);
      default:
        return Colors.grey;
    }
  }

  String _getPlatformInitials() {
    switch (platform.id) {
      case 'netflix':
        return 'N';
      case 'disney_plus':
        return 'D+';
      case 'amazon_prime':
        return 'AP';
      case 'hulu':
        return 'H';
      case 'hbo_max':
        return 'HBO';
      case 'apple_tv':
        return 'ATV';
      case 'paramount_plus':
        return 'P+';
      case 'peacock':
        return 'P';
      case 'youtube_tv':
        return 'YT';
      case 'tubi':
        return 'T';
      case 'pluto_tv':
        return 'PT';
      default:
        return platform.name.substring(0, 1);
    }
  }
}

/// Widget to display streaming availability for a movie
class StreamingAvailabilityWidget extends StatelessWidget {
  final Movie movie;
  final bool showPricing;

  const StreamingAvailabilityWidget({
    super.key,
    required this.movie,
    this.showPricing = true,
  });

  @override
  Widget build(BuildContext context) {
    final availability = movie.streamingAvailability;

    if (availability == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available on:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Platform logos
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: availability.platforms.map((platform) {
            return StreamingPlatformLogo(
              platform: platform,
              size: 50,
              showName: true,
            );
          }).toList(),
        ),

        if (showPricing &&
            (availability.rentalPrice != null ||
                availability.purchasePrice != null ||
                availability.isFree)) ...[
          const SizedBox(height: 16),
          Text(
            'Pricing:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildPricingInfo(context, availability),
        ],
      ],
    );
  }

  Widget _buildPricingInfo(
      BuildContext context, MovieStreamingAvailability availability) {
    final List<Widget> pricingWidgets = [];

    if (availability.isFree) {
      pricingWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green),
          ),
          child: Text(
            'Free',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (availability.rentalPrice != null) {
      pricingWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue),
          ),
          child: Text(
            'Rent: ${availability.rentalPrice}',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (availability.purchasePrice != null) {
      pricingWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange),
          ),
          child: Text(
            'Buy: ${availability.purchasePrice}',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pricingWidgets,
    );
  }
}

/// Widget to display streaming platform filter chips
class StreamingPlatformFilterChips extends StatelessWidget {
  final List<StreamingPlatform> platforms;
  final List<String> selectedPlatformIds;
  final Function(String) onPlatformSelected;
  final Function(String) onPlatformDeselected;

  const StreamingPlatformFilterChips({
    super.key,
    required this.platforms,
    required this.selectedPlatformIds,
    required this.onPlatformSelected,
    required this.onPlatformDeselected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: platforms.map((platform) {
        final isSelected = selectedPlatformIds.contains(platform.id);

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamingPlatformLogo(
                platform: platform,
                size: 16,
                showName: false,
              ),
              const SizedBox(width: 4),
              Text(
                platform.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onPlatformSelected(platform.id);
            } else {
              onPlatformDeselected(platform.id);
            }
          },
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }
}

/// Widget to display streaming platform statistics
class StreamingPlatformStats extends StatelessWidget {
  final Map<String, int> platformStats;
  final List<StreamingPlatform> availablePlatforms;

  const StreamingPlatformStats({
    super.key,
    required this.platformStats,
    required this.availablePlatforms,
  });

  @override
  Widget build(BuildContext context) {
    if (platformStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedStats = platformStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Availability',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...sortedStats.map((entry) {
          final platform = availablePlatforms.firstWhere(
            (p) => p.id == entry.key,
            orElse: () => StreamingPlatform(
              id: entry.key,
              name: entry.key,
              logoPath: '',
            ),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                StreamingPlatformLogo(
                  platform: platform,
                  size: 30,
                  showName: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    platform.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
