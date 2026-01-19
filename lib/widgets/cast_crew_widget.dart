import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';

/// Widget for displaying a cast member card
class CastMemberCard extends StatelessWidget {
  final CastMember castMember;
  final VoidCallback? onTap;

  const CastMemberCard({
    super.key,
    required this.castMember,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Profile image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: ClipOval(
                child: castMember.profileUrl != null
                    ? CachedNetworkImage(
                        imageUrl: castMember.profileUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey.shade600,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Name
            Text(
              castMember.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Character name
            if (castMember.character != null) ...[
              const SizedBox(height: 4),
              Text(
                castMember.character!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a crew member card
class CrewMemberCard extends StatelessWidget {
  final CrewMember crewMember;
  final VoidCallback? onTap;

  const CrewMemberCard({
    super.key,
    required this.crewMember,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Profile image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: ClipOval(
                child: crewMember.profileUrl != null
                    ? CachedNetworkImage(
                        imageUrl: crewMember.profileUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey.shade600,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Name
            Text(
              crewMember.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Job
            if (crewMember.job != null) ...[
              const SizedBox(height: 4),
              Text(
                crewMember.job!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying cast list
class CastListWidget extends StatelessWidget {
  final List<CastMember> cast;
  final Function(CastMember)? onCastMemberTap;
  final String title;
  final bool showTitle;
  final int maxItems;

  const CastListWidget({
    super.key,
    required this.cast,
    this.onCastMemberTap,
    this.title = 'Cast',
    this.showTitle = true,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCast = cast.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cast.length > maxItems)
                  Text(
                    '${cast.length} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayCast.length,
            itemBuilder: (context, index) {
              return CastMemberCard(
                castMember: displayCast[index],
                onTap: () => onCastMemberTap?.call(displayCast[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying crew list
class CrewListWidget extends StatelessWidget {
  final List<CrewMember> crew;
  final Function(CrewMember)? onCrewMemberTap;
  final String title;
  final bool showTitle;
  final int maxItems;

  const CrewListWidget({
    super.key,
    required this.crew,
    this.onCrewMemberTap,
    this.title = 'Crew',
    this.showTitle = true,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (crew.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCrew = crew.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (crew.length > maxItems)
                  Text(
                    '${crew.length} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayCrew.length,
            itemBuilder: (context, index) {
              return CrewMemberCard(
                crewMember: displayCrew[index],
                onTap: () => onCrewMemberTap?.call(displayCrew[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying cast and crew in a tabbed view
class CastCrewTabWidget extends StatefulWidget {
  final List<CastMember> cast;
  final List<CrewMember> crew;
  final Function(CastMember)? onCastMemberTap;
  final Function(CrewMember)? onCrewMemberTap;

  const CastCrewTabWidget({
    super.key,
    required this.cast,
    required this.crew,
    this.onCastMemberTap,
    this.onCrewMemberTap,
  });

  @override
  State<CastCrewTabWidget> createState() => _CastCrewTabWidgetState();
}

class _CastCrewTabWidgetState extends State<CastCrewTabWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            tabs: [
              Tab(text: 'Cast (${widget.cast.length})'),
              Tab(text: 'Crew (${widget.crew.length})'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Tab content
        SizedBox(
          height: 140,
          child: TabBarView(
            controller: _tabController,
            children: [
              CastListWidget(
                cast: widget.cast,
                onCastMemberTap: widget.onCastMemberTap,
                showTitle: false,
              ),
              CrewListWidget(
                crew: widget.crew,
                onCrewMemberTap: widget.onCrewMemberTap,
                showTitle: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 