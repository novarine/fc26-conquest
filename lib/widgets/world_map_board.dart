import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/campaign_state.dart';
import '../models/region.dart';
import '../models/team.dart';
import '../utils/color_utils.dart';
import 'team_badge.dart';

class WorldMapBoard extends StatefulWidget {
  const WorldMapBoard({
    super.key,
    required this.campaign,
    required this.teams,
  });

  final CampaignState campaign;
  final List<Team> teams;

  @override
  State<WorldMapBoard> createState() => _WorldMapBoardState();
}

class _WorldMapBoardState extends State<WorldMapBoard> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  Set<int> _hoveredRegionIds = const {};
  double _zoom = 1.0;

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regions = [...widget.campaign.regions]..sort((a, b) => a.id.compareTo(b.id));
    final layout = _BoardLayout.fromRegionCount(regions.length, zoom: _zoom);
    final boardSize = layout.boardSize;
    final shapes = _buildShapes(regions, layout);
    final territories = _buildTerritories(regions, shapes);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF112A42), Color(0xFF214A72), Color(0xFF15273A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF374151), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: boardSize.width,
                  height: boardSize.height,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: boardSize,
                        painter: _MergedMapPainter(
                          regions: regions,
                          teams: widget.teams,
                          shapes: shapes,
                          hoveredRegionIds: _hoveredRegionIds,
                        ),
                      ),
                      ...territories.map((territory) {
                        final team = _teamById(territory.ownerId);
                        if (team == null) {
                          return const SizedBox.shrink();
                        }

                        final center = territory.center;
                        final badgeSize = territory.regionIds.length >= 4 ? 74.0 : 64.0;
                        return Positioned(
                          left: center.dx - (badgeSize / 2),
                          top: center.dy - (badgeSize / 2),
                          child: MouseRegion(
                            onEnter: (_) {
                              if (territory.regionIds.isNotEmpty) {
                                setState(() {
                                  _hoveredRegionIds = territory.regionIds.toSet();
                                });
                              }
                            },
                            onExit: (_) => setState(() => _hoveredRegionIds = const {}),
                            child: Tooltip(
                              preferBelow: false,
                              richMessage: TextSpan(
                                text: '${team.name}\n',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Gebiete: ${territory.regionIds.length}\n',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: 'Team Rating: ${team.rating}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              child: TeamBadge(team: team, size: badgeSize, showFrame: true),
                            ),
                          ),
                        );
                      }),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _ZoomControls(
                          zoom: _zoom,
                          onZoomIn: () => setState(() {
                            _zoom = (_zoom + 0.1).clamp(0.7, 1.8);
                          }),
                          onZoomOut: () => setState(() {
                            _zoom = (_zoom - 0.1).clamp(0.7, 1.8);
                          }),
                          onReset: () => setState(() {
                            _zoom = 1.0;
                          }),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Scrollbars: Karte bewegen',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Team? _teamById(int id) {
    for (final team in widget.teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  Map<int, _RegionShape> _buildShapes(List<Region> regions, _BoardLayout layout) {
    if (regions.isEmpty) {
      return const {};
    }

    final left = 72.0;
    final top = 70.0;
    final right = layout.boardSize.width - 72;
    final bottom = layout.boardSize.height - 70;

    final cellWidth = (right - left) / layout.cols;
    final cellHeight = (bottom - top) / layout.rows;

    final anchors = List.generate(layout.rows + 1, (r) {
      return List.generate(layout.cols + 1, (c) {
        final xBase = left + (cellWidth * c);
        final yBase = top + (cellHeight * r);

        final xNoise = _noise(r, c, 0.45) * (cellWidth * 0.11);
        final yNoise = _noise(r, c, 0.93) * (cellHeight * 0.11);

        return Offset(
          xBase + (c == 0 || c == layout.cols ? 0 : xNoise),
          yBase + (r == 0 || r == layout.rows ? 0 : yNoise),
        );
      });
    });

    final shapes = <int, _RegionShape>{};
    for (var index = 0; index < regions.length; index++) {
      final row = index ~/ layout.cols;
      final col = index % layout.cols;

      if (row >= layout.rows) {
        continue;
      }

      final regionId = regions[index].id;
      final a = anchors[row][col];
      final b = anchors[row][col + 1];
      final c = anchors[row + 1][col + 1];
      final d = anchors[row + 1][col];

      shapes[regionId] = _RegionShape(
        id: regionId,
        points: [a, b, c, d],
      );
    }

    return shapes;
  }

  List<_Territory> _buildTerritories(
    List<Region> regions,
    Map<int, _RegionShape> shapes,
  ) {
    final regionById = {for (final region in regions) region.id: region};
    final visited = <int>{};
    final territories = <_Territory>[];

    for (final region in regions) {
      if (visited.contains(region.id)) {
        continue;
      }

      final ownerId = region.ownerId;
      final stack = <int>[region.id];
      final component = <int>[];

      while (stack.isNotEmpty) {
        final currentId = stack.removeLast();
        if (!visited.add(currentId)) {
          continue;
        }

        final current = regionById[currentId];
        if (current == null || current.ownerId != ownerId) {
          continue;
        }

        component.add(currentId);

        for (final neighborId in current.neighbors) {
          final neighbor = regionById[neighborId];
          if (neighbor == null || neighbor.ownerId != ownerId || visited.contains(neighborId)) {
            continue;
          }
          stack.add(neighborId);
        }
      }

      if (component.isEmpty) {
        continue;
      }

      var cx = 0.0;
      var cy = 0.0;
      var count = 0;
      final regionCenters = <Offset>[];
      for (final id in component) {
        final shape = shapes[id];
        if (shape == null) {
          continue;
        }
        final center = _polygonCenter(shape.points);
        regionCenters.add(center);
        cx += center.dx;
        cy += center.dy;
        count++;
      }

      final averageCenter = count == 0 ? const Offset(0, 0) : Offset(cx / count, cy / count);
      Offset stableCenter = averageCenter;
      if (regionCenters.isNotEmpty) {
        stableCenter = regionCenters.reduce((best, current) {
          final bestDistance = (best - averageCenter).distanceSquared;
          final currentDistance = (current - averageCenter).distanceSquared;
          return currentDistance < bestDistance ? current : best;
        });
      }

      territories.add(
        _Territory(
          ownerId: ownerId,
          regionIds: component,
          center: stableCenter,
        ),
      );
    }

    return territories;
  }

  double _noise(int row, int col, double phase) {
    final value = math.sin((row + 1) * 11.137 + (col + 1) * 83.971 + phase * 37.0);
    return value.clamp(-1.0, 1.0);
  }

  Offset _polygonCenter(List<Offset> points) {
    var x = 0.0;
    var y = 0.0;
    for (final point in points) {
      x += point.dx;
      y += point.dy;
    }
    return Offset(x / points.length, y / points.length);
  }
}

class _MergedMapPainter extends CustomPainter {
  const _MergedMapPainter({
    required this.regions,
    required this.teams,
    required this.shapes,
    required this.hoveredRegionIds,
  });

  final List<Region> regions;
  final List<Team> teams;
  final Map<int, _RegionShape> shapes;
  final Set<int> hoveredRegionIds;

  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10253A), Color(0xFF173D5D), Color(0xFF123552)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), waterPaint);

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = const Color(0x2A7DD3FC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 22, size.width - 48, size.height - 44),
        const Radius.circular(26),
      ),
      framePaint,
    );

    for (final region in regions) {
      final shape = shapes[region.id];
      if (shape == null) {
        continue;
      }

      final team = _teamById(region.ownerId);
      final baseColor = parseHexColor(team?.primaryColor ?? '#64748B');
      final path = Path()..addPolygon(shape.points, true);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = hoveredRegionIds.contains(region.id)
            ? Color.lerp(baseColor, Colors.white, 0.2) ?? baseColor
            : baseColor.withValues(alpha: 0.94);
      canvas.drawPath(path, fillPaint);
    }

    final edgeMap = <String, _EdgeAggregate>{};
    for (final region in regions) {
      final shape = shapes[region.id];
      if (shape == null) {
        continue;
      }

      final points = shape.points;
      for (var i = 0; i < points.length; i++) {
        final a = points[i];
        final b = points[(i + 1) % points.length];
        final key = _edgeKey(a, b);
        final entry = edgeMap.putIfAbsent(
          key,
          () => _EdgeAggregate(start: a, end: b, owners: <int>{}, touches: 0),
        );
        entry.touches += 1;
        entry.owners.add(region.ownerId);
      }
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xAA3D2A1F);

    final coastPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.22);

    for (final edge in edgeMap.values) {
      if (edge.touches == 1) {
        canvas.drawLine(edge.start, edge.end, coastPaint);
        continue;
      }

      if (edge.owners.length <= 1) {
        continue;
      }

      canvas.drawLine(edge.start, edge.end, borderPaint);
    }

    // Hover effect is handled by brighter fill; no extra stroke to avoid false inner borders.
  }

  String _edgeKey(Offset a, Offset b) {
    final aKey = '${a.dx.toStringAsFixed(3)}_${a.dy.toStringAsFixed(3)}';
    final bKey = '${b.dx.toStringAsFixed(3)}_${b.dy.toStringAsFixed(3)}';
    if (aKey.compareTo(bKey) < 0) {
      return '$aKey|$bKey';
    }
    return '$bKey|$aKey';
  }

  Team? _teamById(int id) {
    for (final team in teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _MergedMapPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.teams != teams ||
        oldDelegate.hoveredRegionIds != hoveredRegionIds;
  }
}

class _RegionShape {
  const _RegionShape({
    required this.id,
    required this.points,
  });

  final int id;
  final List<Offset> points;
}

class _Territory {
  const _Territory({
    required this.ownerId,
    required this.regionIds,
    required this.center,
  });

  final int ownerId;
  final List<int> regionIds;
  final Offset center;
}

class _EdgeAggregate {
  _EdgeAggregate({
    required this.start,
    required this.end,
    required this.owners,
    required this.touches,
  });

  final Offset start;
  final Offset end;
  final Set<int> owners;
  int touches;
}

class _BoardLayout {
  const _BoardLayout({
    required this.cols,
    required this.rows,
    required this.boardSize,
  });

  final int cols;
  final int rows;
  final Size boardSize;

  factory _BoardLayout.fromRegionCount(int regionCount, {required double zoom}) {
    final cols = math.max(2, math.sqrt(regionCount).ceil());
    final rows = (regionCount / cols).ceil();

    final baseWidth = math.max(580.0, (cols * 240).toDouble());
    final baseHeight = math.max(420.0, (rows * 220).toDouble());
    final width = baseWidth * zoom;
    final height = baseHeight * zoom;
    return _BoardLayout(
      cols: cols,
      rows: rows,
      boardSize: Size(width, height),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove, color: Colors.white),
            tooltip: 'Zoom out',
          ),
          Text(
            '${(zoom * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Zoom in',
          ),
          TextButton(
            onPressed: onReset,
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
