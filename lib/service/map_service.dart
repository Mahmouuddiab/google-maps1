import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class MapsService {

  static const String googleApiKey = "AIzaSyDclhTzs0uMcg-9rQ5_6UYjvu7FKqHh-mY";

  /// Check if location services enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    return permission;
  }

  /// Get current device location
  Future<LatLng> getCurrentLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    // Check if GPS is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    // Check permission
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    // Get location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  /// Stream location updates
  Stream<LatLng> locationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Move camera to location
  Future<void> moveCamera({
    required GoogleMapController controller,
    required LatLng location,
    double zoom = 15,
  }) async {
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: zoom,
        ),
      ),
    );
  }

  /// Create marker
  Marker createMarker({
    required String id,
    required LatLng position,
    String? title,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
      ),
    );
  }

  /// Convert address -> coordinates
  Future<LatLng?> getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        return LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    return null;
  }

  /// Convert coordinates -> address
  Future<String?> getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    return null;
  }

  /// Search places using Google Places API
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {

    final url = "https://places.googleapis.com/v1/places:searchText";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": googleApiKey,
        "X-Goog-FieldMask":
        "places.id,places.displayName,places.formattedAddress,places.location",
      },
      body: jsonEncode({
        "textQuery": query,
      }),
    );

    final data = json.decode(response.body);

    debugPrint("NEW API RESPONSE: ${response.body}");

    if (response.statusCode == 200) {

      final List results = data['places'] ?? [];

      return results.map<Map<String, dynamic>>((place) {
        return {
          "place_id": place['id'],
          "name": place['displayName']['text'],
          "formatted_address": place['formattedAddress'],
          "geometry": {
            "location": {
              "lat": place['location']['latitude'],
              "lng": place['location']['longitude'],
            }
          }
        };
      }).toList();

    } else {
      throw Exception(data['error'] ?? "Places API error");
    }
  }

  /// Get LatLng from place result
  LatLng getLatLngFromPlace(Map<String, dynamic> place) {
    final location = place['geometry']['location'];

    return LatLng(
      location['lat'],
      location['lng'],
    );
  }

  /// Calculate distance between two points (meters)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
}