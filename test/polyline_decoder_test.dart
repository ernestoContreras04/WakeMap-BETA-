import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_definitivo2/utils/polyline_decoder.dart';

void main() {
  test('decodePolyline returns correct LatLng points', () {
    final encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';  
    final points = decodePolyline(encoded);

    expect(points.length, greaterThan(0));
    expect(points.first.latitude, closeTo(38.5, 0.001));
    expect(points.first.longitude, closeTo(-120.2, 0.001));
    expect(points[1].latitude, closeTo(40.7, 0.001));
    expect(points[1].longitude, closeTo(-120.95, 0.001));
  });
}

