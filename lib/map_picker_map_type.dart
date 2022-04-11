enum MapPickerMapType {
  roads,
  standard,
  terrain,
  roadmap,
  satellite,
  terrainOnly,
  hybrid,
}

extension MapPickerMapTypeHelper on MapPickerMapType {
  String get tileCode {
    switch (this) {
      case MapPickerMapType.roads:
        return 'h';
      case MapPickerMapType.standard:
        return 'm';
      case MapPickerMapType.terrain:
        return 'p';
      case MapPickerMapType.roadmap:
        return 'r';
      case MapPickerMapType.satellite:
        return 's';
      case MapPickerMapType.terrainOnly:
        return 't';
      case MapPickerMapType.hybrid:
        return 'y';
    }
  }
}
