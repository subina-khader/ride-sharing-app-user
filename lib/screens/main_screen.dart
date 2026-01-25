import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trippo_mobile_app/assistants/location_search_delegate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trippo_mobile_app/assistants/route_helper.dart';
import 'package:trippo_mobile_app/models/ride_request_model.dart';
import 'package:trippo_mobile_app/models/user_model.dart';
import 'package:trippo_mobile_app/global/global.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LatLng? currentLocation;
  LatLng? fromLocation;
  String? fromAddress;
  String? toAddress;
  LatLng? toLocation;
  MapController mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  // Online drivers
  Map<String, dynamic> onlineDrivers = {};
  StreamSubscription<DatabaseEvent>? _driversStream;

  // Route data
  List<LatLng> routePoints = [];
  double? tripDistance;
  double? tripDuration;
  bool isLoadingRoute = false;

  // Ride request
  String? selectedVehicleType;
  double? selectedFare;
  String? activeRideRequestId;
  StreamSubscription<DatabaseEvent>? _rideRequestStream;

  // Driver info (after acceptance)
  String? assignedDriverName;
  String? assignedDriverPhone;
  String? assignedVehicleModel;
  String? assignedVehicleNumber;
  String? rideStatus; // waiting, accepted, arrived, started, completed

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToOnlineDrivers();
    _loadUserData();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _driversStream?.cancel();
    _rideRequestStream?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    currentUser = firebaseAuth.currentUser;

    if (currentUser != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(currentUser!.uid);

      DatabaseEvent event = await userRef.once();

      if (event.snapshot.value != null) {
        setState(() {
          userModelCurrentInfo = UserModel.fromSnapshot(event.snapshot);
        });
        print("User data loaded: ${userModelCurrentInfo!.name}");
      }
    }
  }

  void _listenToOnlineDrivers() {
    DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers");

    _driversStream = driversRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> drivers = event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, dynamic> onlineDriversTemp = {};

        drivers.forEach((key, value) {
          if (value['status'] == 'online' &&
              value['isAvailable'] == true &&
              value['location'] != null) {
            onlineDriversTemp[key] = {
              'name': value['name'] ?? 'Driver',
              'vehicleType': value['vehicleType'] ?? 'Car',
              'vehicleModel': value['vehicleModel'] ?? 'Unknown',
              'vehicleNumber': value['vehicleNumber'] ?? '',
              'latitude': value['location']['latitude'],
              'longitude': value['location']['longitude'],
              'ratings': value['ratings'] ?? 5.0,
            };
          }
        });

        setState(() {
          onlineDrivers = onlineDriversTemp;
        });
      }
    });
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
        if (fromLocation == null) {
          fromLocation = newLocation;
        }
      });

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
      fromLocation = loc;
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
          mapController.move(selectedLocation, 15.0);
        } else {
          toAddress = result['display_name'];
          toLocation = selectedLocation;
        }
      });

      if (fromLocation != null && toLocation != null) {
        _drawRoute();
      }
    }
  }

  Future<void> _drawRoute() async {
    if (fromLocation == null || toLocation == null) return;

    setState(() {
      isLoadingRoute = true;
    });

    final routeData = await RouteHelper.getRoute(fromLocation!, toLocation!);

    if (routeData['success'] == true) {
      setState(() {
        routePoints = routeData['points'];
        tripDistance = routeData['distance'];
        tripDuration = routeData['duration'];
        isLoadingRoute = false;
      });

      _fitRouteBounds();
    } else {
      setState(() {
        isLoadingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not draw route: ${routeData['error']}')),
      );
    }
  }

  void _fitRouteBounds() {
    if (routePoints.isEmpty) return;

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (var point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _resetToCurrentLocation() {
    if (currentLocation != null) {
      _getAddressFromLatLng(currentLocation!).then((address) {
        setState(() {
          fromLocation = currentLocation;
          fromAddress = address;
          mapController.move(currentLocation!, 15.0);

          if (toLocation != null) {
            _drawRoute();
          }
        });
      });
    }
  }

  void _showFareDialog() {
    if (tripDistance == null) return;

    showDialog(
      context: context,
      builder: (context) {
        bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkTheme ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Vehicle Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkTheme ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Distance:'),
                          Text(
                            RouteHelper.formatDistance(tripDistance!),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration:'),
                          Text(
                            RouteHelper.formatDuration(tripDuration!),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildVehicleOption('Bike', Icons.two_wheeler, darkTheme),
                _buildVehicleOption('CNG', Icons.airport_shuttle, darkTheme),
                _buildVehicleOption('Car', Icons.directions_car, darkTheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleOption(String vehicleType, IconData icon, bool darkTheme) {
    double fare = RouteHelper.calculateFare(tripDistance!, vehicleType);

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedVehicleType = vehicleType;
          selectedFare = fare;
        });
        _requestRide();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    RouteHelper.formatDuration(tripDuration!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${fare.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestRide() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    if (userModelCurrentInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading user data... Please try again')),
      );
      return;
    }

    if (fromLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup location')),
      );
      return;
    }

    if (toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination')),
      );
      return;
    }

    if (selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select vehicle type')),
      );
      return;
    }

    print("Creating ride request...");

    RideRequest rideRequest = RideRequest(
      userId: currentUser!.uid,
      userName: userModelCurrentInfo!.name,
      userPhone: userModelCurrentInfo!.phone,
      pickupAddress: fromAddress,
      pickupLatitude: fromLocation!.latitude,
      pickupLongitude: fromLocation!.longitude,
      destinationAddress: toAddress,
      destinationLatitude: toLocation!.latitude,
      destinationLongitude: toLocation!.longitude,
      vehicleType: selectedVehicleType,
      fare: selectedFare,
      distance: tripDistance,
      duration: tripDuration,
      status: 'waiting',
    );

    try {
      DatabaseReference rideRequestsRef = FirebaseDatabase.instance
          .ref()
          .child("rideRequests");

      DatabaseReference newRequestRef = rideRequestsRef.push();

      await newRequestRef.set(rideRequest.toMap());

      setState(() {
        activeRideRequestId = newRequestRef.key;
        rideStatus = 'waiting';
      });

      print("Ride request created with ID: ${newRequestRef.key}");

      // Listen for updates to this ride request
      _listenToRideRequest();

      _showWaitingDialog();
    } catch (e) {
      print("Error creating ride request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating request: $e')),
      );
    }
  }

  void _listenToRideRequest() {
    if (activeRideRequestId == null) return;

    DatabaseReference requestRef = FirebaseDatabase.instance
        .ref()
        .child("rideRequests")
        .child(activeRideRequestId!);

    _rideRequestStream = requestRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        RideRequest updatedRequest = RideRequest.fromSnapshot(event.snapshot);

        setState(() {
          rideStatus = updatedRequest.status;

          if (updatedRequest.status == 'accepted') {
            assignedDriverName = updatedRequest.driverName;
            assignedDriverPhone = updatedRequest.driverPhone;
            assignedVehicleModel = updatedRequest.vehicleModel;
            assignedVehicleNumber = updatedRequest.vehicleNumber;
          }
        });

        print("Ride status updated: ${updatedRequest.status}");

        // Handle different statuses
        if (updatedRequest.status == 'accepted') {
          // Close searching dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          _showDriverDetailsDialog();

        } else if (updatedRequest.status == 'arrived') {
          _showStatusDialog(
              'Driver Arrived!',
              'Your driver has arrived at the pickup location',
              Icons.location_on,
              Colors.green
          );

        } else if (updatedRequest.status == 'started') {
          _showStatusDialog(
              'Trip Started!',
              'Enjoy your ride to the destination',
              Icons.directions_car,
              Colors.blue
          );

        } else if (updatedRequest.status == 'completed') {
          _showCompletionDialog();
        }
      }
    });
  }
  void _showStatusDialog(String title, String message, IconData icon, Color color) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkTheme ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 60),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkTheme ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 15),
              Text(
                'Trip Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Fare',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${selectedFare?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Thank you for riding with us!',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetTrip();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: darkTheme ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetTrip() {
    setState(() {
      activeRideRequestId = null;
      selectedVehicleType = null;
      selectedFare = null;
      rideStatus = null;
      assignedDriverName = null;
      assignedDriverPhone = null;
      assignedVehicleModel = null;
      assignedVehicleNumber = null;
      routePoints = [];
      toLocation = null;
      toAddress = null;
    });
    _rideRequestStream?.cancel();
  }

  void _showWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkTheme ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Searching for driver...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkTheme ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please wait while we find a ${selectedVehicleType?.toLowerCase()} for you',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _cancelRideRequest();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDriverDetailsDialog() {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkTheme ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 15),
              Text(
                'Driver Found!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignedDriverName ?? 'Driver',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                assignedDriverPhone ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              assignedVehicleModel ?? 'Car',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Number',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              assignedVehicleNumber ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Driver is on the way to pickup location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: darkTheme ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelRideRequest() async {
    if (activeRideRequestId != null) {
      await FirebaseDatabase.instance
          .ref()
          .child("rideRequests")
          .child(activeRideRequestId!)
          .remove();

      _rideRequestStream?.cancel();

      setState(() {
        activeRideRequestId = null;
        selectedVehicleType = null;
        selectedFare = null;
        rideStatus = null;
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

              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
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
                  ...onlineDrivers.entries.map((entry) {
                    LatLng driverLocation = LatLng(
                      entry.value['latitude'],
                      entry.value['longitude'],
                    );
                    return Marker(
                      point: driverLocation,
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          entry.value['vehicleType'] == 'Bike'
                              ? Icons.two_wheeler
                              : entry.value['vehicleType'] == 'CNG'
                              ? Icons.airport_shuttle
                              : Icons.directions_car,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          if (isLoadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
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

                        if (tripDistance != null && rideStatus == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              onPressed: _showFareDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkTheme
                                    ? Colors.amber.shade400
                                    : Colors.blue,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Request Ride',
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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