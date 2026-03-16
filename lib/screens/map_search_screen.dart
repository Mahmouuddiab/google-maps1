import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_feature/service/map_service.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {

  final MapsService _mapsService = MapsService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;

  LatLng? _currentLocation;

  Set<Marker> _markers = {};

  List<Map<String, dynamic>> _searchResults = [];

  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  /// Load device location
  Future<void> _loadCurrentLocation() async {

    try {

      LatLng location = await _mapsService.getCurrentLocation();

      final marker = _mapsService.createMarker(
        id: "current_location",
        position: location,
        title: "My Location",
      );

      setState(() {
        _currentLocation = location;
        _markers = {marker};
        _loadingLocation = false;
      });

      if (_mapController != null) {
        await _mapsService.moveCamera(
          controller: _mapController!,
          location: location,
        );
      }

    } catch (e) {

      setState(() {
        _loadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// Search places
  Future<void> _searchPlaces(String query) async {

    if (query.isEmpty) return;

    final results = await _mapsService.searchPlaces(query);

    setState(() {
      _searchResults = results;
    });
  }

  /// Select place from search
  Future<void> _selectPlace(Map<String, dynamic> place) async {

    FocusScope.of(context).unfocus();

    LatLng location = _mapsService.getLatLngFromPlace(place);

    final marker = _mapsService.createMarker(
      id: place['place_id'],
      position: location,
      title: place['name'],
    );

    setState(() {
      _markers = {marker};
      _currentLocation = location;
      _searchResults.clear();
      _searchController.clear();
    });

    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 16,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Google Maps Search"),
      ),

      body: Stack(
        children: [

          /// Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          /// Search box
          Positioned(
            top: 20,
            left: 15,
            right: 15,
            child: Column(
              children: [

                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search location...",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                    ),
                    onSubmitted: _searchPlaces,
                  ),
                ),

                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {

                        final place = _searchResults[index];

                        return ListTile(
                          title: Text(place['name']),
                          subtitle: Text(place['formatted_address'] ?? ""),
                          onTap: () => _selectPlace(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          /// Current location button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _loadCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
} 