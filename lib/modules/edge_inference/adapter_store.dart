import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AdapterStore {
  // The directory which has the user's personlaized weights
  Future<Directory> adapterDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final sub = Directory('${dir.path}/adapters');
    if (!await sub.exists()) {
      await sub.create(recursive: true);
    }
    return sub;
  }

  // The adapter file itself
  Future<File> activeAdapterFile() async {
    final dir = await adapterDirectory();
    return File('${dir.path}/user_adapter.bin');
  }
}
