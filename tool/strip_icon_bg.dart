// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Dev script: removes the opaque checkerboard background some downloaded icons
/// ship with (no alpha channel) by flood-filling from the image edges. Connected
/// "background-like" pixels (near-white / near-light-grey) become transparent;
/// the icon's darker outline stops the fill, so the art is preserved.
///
/// Usage: dart run tool/strip_icon_bg.dart [path ...]
/// Defaults to assets/buttons/premium_icon_option_2.png.
void main(List<String> args) {
  final paths = args.isNotEmpty
      ? args
      : ['assets/buttons/premium_icon_option_2.png'];
  for (final path in paths) {
    _strip(File(path));
  }
}

/// A pixel counts as background if it's bright and roughly grey (white or the
/// light-grey checker squares) — not the gold/brown/cream icon art.
bool _isBackground(img.Pixel p) {
  final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
  if (r < 175 || g < 175 || b < 175) return false; // dark → icon
  final mx = [r, g, b].reduce((a, b) => a > b ? a : b);
  final mn = [r, g, b].reduce((a, b) => a < b ? a : b);
  return (mx - mn) <= 28; // near-neutral → checker/white
}

void _strip(File file) {
  if (!file.existsSync()) {
    print('skip (not found): ${file.path}');
    return;
  }
  final original = img.decodeImage(file.readAsBytesSync());
  if (original == null) {
    print('skip (decode failed): ${file.path}');
    return;
  }
  final image = original.convert(numChannels: 4);
  final w = image.width, h = image.height;
  final visited = List.generate(h, (_) => List<bool>.filled(w, false));
  final stack = <List<int>>[];

  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    if (visited[y][x]) return;
    if (_isBackground(image.getPixel(x, y))) stack.add([x, y]);
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }

  var cleared = 0;
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    final x = p[0], y = p[1];
    if (x < 0 || y < 0 || x >= w || y >= h) continue;
    if (visited[y][x]) continue;
    visited[y][x] = true;
    if (!_isBackground(image.getPixel(x, y))) continue;
    image.setPixelRgba(x, y, 0, 0, 0, 0);
    cleared++;
    stack.add([x + 1, y]);
    stack.add([x - 1, y]);
    stack.add([x, y + 1]);
    stack.add([x, y - 1]);
  }

  file.writeAsBytesSync(Uint8List.fromList(img.encodePng(image)));
  print('✅ ${file.path}: cleared $cleared background px (${w}x$h)');
}
