
# Trippo App - User

Trippo is a Flutter-based ride-booking application that allows users to book rides by selecting pickup and destination locations, viewing routes, checking estimated fares, and requesting rides from available drivers.

The application uses Firebase for authentication and real-time ride management, along with OpenStreetMap and OSRM for location search and route calculation.

## Features

### User Authentication
- User registration with name, email, phone number, and address.
- Login using email and password.
- Forgot password functionality with email reset link.
- Persistent authentication session.

### Location & Maps
- Interactive OpenStreetMap integration.
- Current location detection using GPS.
- Search pickup and destination locations using OpenStreetMap Nominatim.
- Display selected locations on the map.

### Route & Fare Calculation
- Fetch driving routes using OSRM routing service.
- Display route polylines on the map.
- Calculate travel distance and estimated duration.
- Automatically calculate fares based on vehicle type and distance.

### 🚖 Ride Booking
- Select vehicle type (Bike, CNG/Auto, or Car).
- Create ride requests with pickup and destination details.
- Store ride information in Firebase Realtime Database.
- Track ride status through real-time database updates.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Cross-platform application development |
| Firebase Core | Firebase initialization |
| Firebase Authentication | User authentication |
| Firebase Realtime Database | User profiles and ride management |
| Firebase Storage | Cloud storage integration |
| Firebase Cloud Messaging | Push notification integration |
| Flutter Map | Interactive map visualization |
| OpenStreetMap | Map tiles |
| Nominatim | Location search and geocoding |
| OSRM | Driving route calculation |
| Geolocator | GPS and location tracking |
| Geocoding | Address and coordinate conversion |
| HTTP | API communication |



## Firebase Database Structure

The application uses Firebase Realtime Database to manage user information and ride requests.

```text
users/
  └── userId/
      ├── id
      ├── name
      ├── email
      ├── phone
      └── address

rideRequests/
  └── rideRequestId/
      ├── userId
      ├── userName
      ├── userPhone
      ├── pickupAddress
      ├── destinationAddress
      ├── pickupLatitude
      ├── pickupLongitude
      ├── destinationLatitude
      ├── destinationLongitude
      ├── vehicleType
      ├── fare
      ├── distance
      ├── duration
      ├── status
      ├── driverId
      └── requestTime
```

## Fare Calculation

The estimated fare is calculated using a base fare and a per-kilometer rate.

**Fare = Base Fare + (Distance × Per KM Rate)**

| Vehicle Type | Base Fare | Per KM |
|---|---:|---:|
| Bike | ₹20 | ₹8 |
| CNG / Auto | ₹30 | ₹12 |
| Car | ₹50 | ₹15 |

## External APIs & Services

- **OpenStreetMap:** Provides map tiles for map visualization.
- **Nominatim:** Searches locations and returns geographic coordinates.
- **OSRM:** Calculates driving routes, distance, and estimated travel duration.

## Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Firebase project

### Installation

1. Clone the repository:

```bash
git clone https://github.com/subina-khader/ride-sharing-app-user
```

2. Navigate to the project directory:

```bash
cd ride-sharing-app-user
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure Firebase for your Android/iOS application.

5. Add the required Firebase configuration files.

6. Run the application:

```bash
flutter run
```

## Project Information

- **Project Name:** Trippo Rider App
- **Package Name:** trippo_mobile_app
- **Version:** 1.0.0+1
- **Dart SDK:** ^3.8.1

---

**Trippo – Your Ride, Your Journey! 🚕**
