import 'package:latlng/latlng.dart';

class MapPickerTheme {
  final LatLng initialLocation;
  final double zoom;

  final String? lang;

  final String errorAddressMissing;
  final String errorAddressNotFound;
  final String noAddress;

  final String searchLabel;
  final String searchHint;

  MapPickerTheme({
    required this.initialLocation,
    this.zoom = 11,
    this.lang,
    this.errorAddressNotFound = 'Address not found',
    this.errorAddressMissing = 'No address specified',
    this.noAddress = 'No address',
    this.searchHint = 'Search by address...',
    this.searchLabel = 'Search:',
  });
}
