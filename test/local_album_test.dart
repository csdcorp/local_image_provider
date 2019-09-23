import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_album.dart';

void main() {
    test('Correct type returned', () async {
      expect( LocalAlbumType.fromInt(0), LocalAlbumType.all );
      expect( LocalAlbumType.fromInt(0), LocalAlbumType.all );
      expect( LocalAlbumType.fromInt(2), LocalAlbumType.generated );
      expect( LocalAlbumType.fromInt(3), null );
    });
}