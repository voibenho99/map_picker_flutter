import 'package:latlng/latlng.dart';

class MapPickerAddress {
  final String formattedAddress;
  final LatLng? latLng;

  MapPickerAddress({required this.formattedAddress, this.latLng});
}
