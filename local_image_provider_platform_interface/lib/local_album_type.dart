class LocalAlbumType {
  const LocalAlbumType._(this.value);
  static LocalAlbumType fromInt(int value) {
    if (value == null) {
      return album;
    }
    if (value < values.length && value >= 0) {
      return values[value];
    }
    return album;
  }

  final int value;

  static const LocalAlbumType all = LocalAlbumType._(0);
  static const LocalAlbumType album = LocalAlbumType._(1);
  static const LocalAlbumType user = LocalAlbumType._(2);
  static const LocalAlbumType generated = LocalAlbumType._(3);
  static const LocalAlbumType faces = LocalAlbumType._(4);
  static const LocalAlbumType event = LocalAlbumType._(5);
  static const LocalAlbumType imported = LocalAlbumType._(6);
  static const LocalAlbumType shared = LocalAlbumType._(7);
  static const List<LocalAlbumType> values = <LocalAlbumType>[
    all,
    album,
    user,
    generated,
    faces,
    event,
    imported,
    shared,
  ];
}
