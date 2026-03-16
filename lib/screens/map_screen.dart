import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_feature/service/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapsService mapsService = MapsService();

  GoogleMapController? mapController;
  LatLng? currentLocation;
  final Set<Marker> markers = {};
  bool isLoading = true;
  bool locationEnabled = true;

  // Default location (e.g., Riyadh) while GPS loads
  final LatLng defaultLocation = const LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    try {
      locationEnabled = await mapsService.isLocationEnabled();
      if (!locationEnabled) {
        debugPrint("Location services are disabled.");
      }

      await mapsService.requestPermission();

      LatLng location = await mapsService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        currentLocation = location;
        markers.add(
          mapsService.createMarker(
            id: "current_location",
            position: location,
          ),
        );
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Location error: $e");
      if (!mounted) return;
      setState(() {
        currentLocation = defaultLocation;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Map"),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation ?? defaultLocation,
          zoom: 15,
        ),
        markers: markers,
        myLocationEnabled: locationEnabled,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (mapController == null) return;
          try {
            LatLng location = await mapsService.getCurrentLocation();
            mapsService.moveCamera(
              controller: mapController!,
              location: location,
            );
          } catch (e) {
            debugPrint("Error moving camera: $e");
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}