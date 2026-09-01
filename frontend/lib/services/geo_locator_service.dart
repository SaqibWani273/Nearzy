import 'package:flutter/services.dart' show PlatformException;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';

import '../utils/exceptions/custom_exception.dart';

class GeoLocatorService {
  /// Shared entry point for the geocoding plugin. As of geocoding 5.x the
  /// top-level functions were folded into this class.
  static final geocoding.Geocoding _geocoding = geocoding.Geocoding();

  static Future<Position?> getcurrentPosition() async {
    LocationPermission permission;
    final bool locationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      throw CustomException(
        message: "Location Services are Disabled",
        errorType: ErrorType.locationServicesDisabled,
      );
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time we could try
        throw CustomException(
          message: "Please Allow location permission",
          errorType: ErrorType.locationpermissionDenied,
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      throw CustomException(
        message: "Location permissions were denied !!",
        errorType: ErrorType.locationPermissionDeniedPermanently,
      );
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        forceLocationManager: true,
      ),
    );
  }

  static Future<LocationInfo> fetchLocationInfo(
      String? userEnteredLocation) async {
    try {
      late List<geocoding.Placemark> placemarks;
      late double latitude;
      late double longtitude;
      if (userEnteredLocation == null) {
        //position from current location
        final position = await GeoLocatorService.getcurrentPosition();
        if (position == null) {
          throw CustomException(
            errorType: ErrorType.unknown,
            message: 'Something went wrong!,Please try agian',
          );
        }
        placemarks = await _geocoding.placemarkFromCoordinates(
            position.latitude, position.longitude);
        latitude = position.latitude;
        longtitude = position.longitude;
      } else {
        //positon from the user entered address
        final List<geocoding.Location> locations =
            await _geocoding.locationFromAddress(userEnteredLocation);
        if (locations.isEmpty) {
          throw CustomException(
            errorType: ErrorType.noLocationFound,
            message: 'No Location Found',
          );
        }
        //to do: later pass all the location to the function
        //placemarkFromCoordinates to get all the placemarks
        //and let user choose the one he wants
        placemarks = await _geocoding.placemarkFromCoordinates(
            locations[0].latitude, locations[0].longitude);
        longtitude = locations[0].longitude;
        latitude = locations[0].latitude;
      }

      // geocoding 5.x returns an empty list instead of throwing when the
      // coordinates cannot be resolved to an address.
      if (placemarks.isEmpty) {
        throw CustomException(
          errorType: ErrorType.noLocationFound,
          message: 'No Location Found',
        );
      }

      final shortAddress =
          '${placemarks[0].street},${placemarks[0].locality},${placemarks[0].postalCode} ${placemarks[0].country}';
      return LocationInfo(
          completeAddress:
              '${placemarks[0].name}, ${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].postalCode}, ${placemarks[0].country}',
          shortAddress: shortAddress,
          latitude: latitude,
          longtitude: longtitude);
    } on PlatformException {
      throw CustomException(
        errorType: ErrorType.noLocationFound,
        message: 'No Location Found',
      );
    } catch (e) {
      rethrow;
    }
  }
}
