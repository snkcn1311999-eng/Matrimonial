import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as pth;
import 'package:path_provider/path_provider.dart';

class PhotoStore {
  static Directory? _dir;
  static final ImagePicker _picker = ImagePicker();
  static int _counter = 0;

  // Call once at app start
  static Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(pth.join(base.path, 'photos'));
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
  }

  // Pick several photos from the gallery; they are compressed while picking
  static Future<List<XFile>> pick() {
    return _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
  }

  // Copy a picked photo into the app's private folder, returns the file name
  static Future<String> save(XFile x) async {
    final name = '${DateTime.now().microsecondsSinceEpoch}_${_counter++}.jpg';
    await File(x.path).copy(pth.join(_dir!.path, name));
    return name;
  }

  static File fileSync(String name) => File(pth.join(_dir!.path, name));

  static Future<void> remove(String name) async {
    final f = fileSync(name);
    if (await f.exists()) await f.delete();
  }
}

class StoredImage extends StatelessWidget {
  final String name;
  final BoxFit fit;
  final int? cacheWidth;
  const StoredImage(this.name,
      {super.key, this.fit = BoxFit.cover, this.cacheWidth});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      PhotoStore.fileSync(name),
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}
