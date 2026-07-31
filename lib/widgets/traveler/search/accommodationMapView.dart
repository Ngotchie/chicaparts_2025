import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class AccommodationMapView extends StatefulWidget {
  final List<Stay> stays;

  const AccommodationMapView({super.key, required this.stays});

  @override
  State<AccommodationMapView> createState() => _AccommodationMapViewState();
}

class _AccommodationMapViewState extends State<AccommodationMapView> {
  GoogleMapController? _mapController;
  Stay? _selectedStay;

  List<Stay> get _locatedStays =>
      widget.stays.where((stay) => stay.hasLocation).toList();

  @override
  void didUpdateWidget(covariant AccommodationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stays != widget.stays) {
      _selectedStay = null;
      _fitMapToStays();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final locatedStays = _locatedStays;

    if (locatedStays.isEmpty) {
      return _EmptyMapState(message: lang.t('no_map_results'));
    }

    final initialStay = locatedStays.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(initialStay.latitude!, initialStay.longitude!),
              zoom: locatedStays.length == 1 ? 14 : 11,
            ),
            markers: _buildMarkers(locatedStays),
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToStays();
            },
            onTap: (_) => setState(() => _selectedStay = null),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapCountBadge(
              text: '${locatedStays.length} ${lang.t('stays_on_map')}',
            ),
          ),
          if (_selectedStay != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _MapStayCard(stay: _selectedStay!),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<Stay> stays) {
    return stays.map((stay) {
      return Marker(
        markerId: MarkerId(stay.id.toString()),
        position: LatLng(stay.latitude!, stay.longitude!),
        onTap: () {
          setState(() => _selectedStay = stay);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(stay.latitude!, stay.longitude!)),
          );
        },
      );
    }).toSet();
  }

  void _fitMapToStays() {
    final stays = _locatedStays;
    if (_mapController == null || stays.isEmpty) return;

    if (stays.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(stays.first.latitude!, stays.first.longitude!),
          14,
        ),
      );
      return;
    }

    final bounds = _boundsFromStays(stays);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  LatLngBounds _boundsFromStays(List<Stay> stays) {
    var minLat = stays.first.latitude!;
    var maxLat = stays.first.latitude!;
    var minLng = stays.first.longitude!;
    var maxLng = stays.first.longitude!;

    for (final stay in stays) {
      final lat = stay.latitude!;
      final lng = stay.longitude!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    if (minLat == maxLat) {
      minLat -= 0.01;
      maxLat += 0.01;
    }
    if (minLng == maxLng) {
      minLng -= 0.01;
      maxLng += 0.01;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _MapStayCard extends StatelessWidget {
  final Stay stay;

  const _MapStayCard({required this.stay});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final rates = context.watch<ExchangeRateProvider>().rates;
    final displayPrice = CurrencyConverter.format(
      stay.price,
      from: stay.currency,
      to: context.read<CurrencyProvider>().currency,
      rates: rates,
    );

    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: stay.imageUrl.isNotEmpty
                    ? Image.network(
                        stay.imageUrl,
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImageFallback(),
                      )
                    : _ImageFallback(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stay.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stay.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[650]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stay.price > 0
                          ? '$displayPrice / ${lang.t("night")}'
                          : lang.t('contact_us'),
                      style: const TextStyle(
                        color: Color(0xFF244B6B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF244B6B)),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccommodationDetails(
          accommodationId: stay.id,
          dayPrice: stay.price,
          currency: stay.currency,
        ),
      ),
    );
  }
}

class _MapCountBadge extends StatelessWidget {
  final String text;

  const _MapCountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF244B6B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyMapState extends StatelessWidget {
  final String message;

  const _EmptyMapState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      color: Colors.grey.shade200,
      child: Icon(Icons.apartment, color: Colors.grey.shade500),
    );
  }
}
