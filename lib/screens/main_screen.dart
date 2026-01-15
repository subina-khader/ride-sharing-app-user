import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:trippo_mobile_app/screens/login_page.dart';
import 'package:trippo_mobile_app/assistants/location_search_delegate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LatLng? currentLocation;
  LatLng? fromLocation; // Separate from location for "From"
  String? fromAddress;
  String? toAddress;
  LatLng? toLocation;
  final MapController mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    await _checkPermission();
    await _getCurrentLocation();
    _listenToLocationChanges();
  }

  void _listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position pos) async {
      LatLng newLocation = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentLocation = newLocation;
        // Only update fromLocation if user hasn't manually selected a location
        if (fromLocation == null) {
          fromLocation = newLocation;
        }
      });

      // Only update fromAddress if user hasn't manually selected
      if (fromLocation == currentLocation) {
        String address = await _getAddressFromLatLng(newLocation);
        setState(() {
          fromAddress = address;
        });
      }
    });
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, cannot request.',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng loc = LatLng(pos.latitude, pos.longitude);
    String address = await _getAddressFromLatLng(loc);

    setState(() {
      currentLocation = loc;
      fromLocation = loc; // Set initial from location
      fromAddress = address;
    });
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;
      return "${place.street}, ${place.locality}";
    } catch (e) {
      return "Unknown location";
    }
  }

  Future<void> _openSearchDialog({required bool isFrom}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
    );

    if (result != null) {
      LatLng selectedLocation = LatLng(
        double.parse(result['lat']),
        double.parse(result['lon']),
      );

      setState(() {
        if (isFrom) {
          fromAddress = result['display_name'];
          fromLocation = selectedLocation;
          // Update map center to show selected from location
          mapController.move(selectedLocation, 15.0);
        } else {
          toAddress = result['display_name'];
          toLocation = selectedLocation;
        }
      });
    }
  }

  // Reset from location to current location
  void _resetToCurrentLocation() {
    if (currentLocation != null) {
      _getAddressFromLatLng(currentLocation!).then((address) {
        setState(() {
          fromLocation = currentLocation;
          fromAddress = address;
          mapController.move(currentLocation!, 15.0);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: fromLocation ?? currentLocation!,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.trippo_mobile_app',
              ),
              MarkerLayer(
                markers: [
                  // From location marker
                  if (fromLocation != null)
                    Marker(
                      point: fromLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  // To location marker
                  if (toLocation != null)
                    Marker(
                      point: toLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: darkTheme ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: darkTheme
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: GestureDetector(
                                  onTap: () {
                                    _openSearchDialog(isFrom: true);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.blue,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'From',
                                              style: TextStyle(
                                                color: darkTheme
                                                    ? Colors.amber.shade400
                                                    : Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              fromAddress ?? "Getting location...",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Show reset button if from location is not current location
                                      if (fromLocation != currentLocation)
                                        IconButton(
                                          icon: Icon(
                                            Icons.my_location,
                                            size: 20,
                                            color: darkTheme
                                                ? Colors.amber.shade400
                                                : Colors.blue,
                                          ),
                                          onPressed: _resetToCurrentLocation,
                                          tooltip: 'Use current location',
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Divider(
                                height: 1,
                                thickness: 2,
                                color: darkTheme
                                    ? Colors.amber.shade400
                                    : Colors.blue,
                              ),
                              const SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: GestureDetector(
                                  onTap: () {
                                    _openSearchDialog(isFrom: false);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.blue,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'To',
                                              style: TextStyle(
                                                color: darkTheme
                                                    ? Colors.amber.shade400
                                                    : Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              toAddress ?? "Where to?",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}