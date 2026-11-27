import 'dart:convert';
import 'package:flutter/material.dart';
import 'common.dart';
import 'db.dart';
import 'photo_store.dart';

class ProfilesPage extends StatefulWidget {
  final bool recentOnly;
  final bool focusSearch;
  const ProfilesPage(
      {super.key, this.recentOnly = false, this.focusSearch = false});
  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final searchC = TextEditingController();
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final r = await AppDb.list(
        query: searchC.text, recentOnly: widget.recentOnly);
    if (mounted) setState(() => items = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recentOnly ? t('recent') : t('view'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchC,
              autofocus: widget.focusSearch,
              onChanged: (_) => load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: t('search_hint'),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(t('no_profiles')))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final age = ageFromDob(p['dob'] as String?);
                      final mp = p['main_photo'] as String?;
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: gold),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: maroon,
                            backgroundImage: mp == null
                                ? null
                                : ResizeImage(
                                    FileImage(PhotoStore.fileSync(mp)),
                                    width: 150),
                            child: mp == null
                                ? Icon(
                                    p['gender'] == 'male'
                                        ? Icons.man
                                        : Icons.woman,
                                    color: cream)
                                : null,
                          ),
                          title: Text(p['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${p['profile_id']} • ${age ?? '-'} ${t('years')} • ${p['district'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProfileDetailPage(p)),
                            );
                            load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileDetailPage extends StatefulWidget {
  final Map<String, dynamic> p;
  const ProfileDetailPage(this.p, {super.key});
  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  List<Map<String, dynamic>> photos = [];

  Map<String, dynamic> get p => widget.p;

  Map<String, dynamic> get extra {
    try {
      return jsonDecode((p['data'] as String?) ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    final r = await AppDb.photos(p['id'] as int);
    if (mounted) setState(() => photos = r);
  }

  Future<void> addPhotos() async {
    final files = await PhotoStore.pick();
    if (files.isEmpty) return;
    for (final x in files) {
      final name = await PhotoStore.save(x);
      await AppDb.addPhoto(p['id'] as int, name);
    }
    await loadPhotos();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('photos_added'))));
    }
  }

  Future<void> openGallery(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoGalleryPage(
          profileId: p['id'] as int,
          photos: List.of(photos),
          initialIndex: index,
        ),
      ),
    );
    loadPhotos();
  }

  Widget row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: maroon))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('confirm_delete')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('no'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('yes'))),
        ],
      ),
    );
    if (ok == true) {
      final files = await AppDb.delete(p['id'] as int);
      for (final f in files) {
        await PhotoStore.remove(f);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('deleted'))));
        Navigator.pop(context);
      }
    }
  }

  Widget mainPhoto() {
    if (photos.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 64, color: maroon),
            const SizedBox(height: 6),
            Text(t('no_photos')),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => openGallery(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 320,
          width: double.infinity,
          child: StoredImage(photos.first['file'] as String,
              fit: BoxFit.cover, cacheWidth: 900),
        ),
      ),
    );
  }

  Widget thumbnails() {
    if (photos.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => openGallery(i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: StoredImage(photos[i]['file'] as String,
                    fit: BoxFit.cover, cacheWidth: 220),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = extra;
    final age = ageFromDob(p['dob'] as String?);
    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: t('delete'),
            onPressed: confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          mainPhoto(),
          thumbnails(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.white,
              foregroundColor: maroon,
              side: const BorderSide(color: gold),
            ),
            icon: const Icon(Icons.add_a_photo),
            label: Text(t('add_photos')),
            onPressed: addPhotos,
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: gold),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  row(t('profile_id'), p['profile_id'] as String?),
                  row(t('name'), p['name'] as String?),
                  row(t('gender'), t((p['gender'] ?? '') as String)),
                  row(t('dob'), showDate(p['dob'] as String?)),
                  row(t('age'), age == null ? null : '$age'),
                  row(t('height'), e['height'] as String?),
                  row(t('marital'), t((e['marital'] ?? '') as String)),
                  row(t('religion'), e['religion'] as String?),
                  row(t('caste'), e['caste'] as String?),
                  row(t('district'), p['district'] as String?),
                  row(t('education'), e['education'] as String?),
                  row(t('profession'), e['profession'] as String?),
                  row(t('mobile'), p['mobile'] as String?),
                  row(t('status'), t((p['status'] ?? '') as String)),
                  row(t('notes'), e['notes'] as String?),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoGalleryPage extends StatefulWidget {
  final int profileId;
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  const PhotoGalleryPage({
    super.key,
    required this.profileId,
    required this.photos,
    required this.initialIndex,
  });
  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  late List<Map<String, dynamic>> photos = widget.photos;
  late int index = widget.initialIndex;
  late PageController pc = PageController(initialPage: widget.initialIndex);
  bool zoomed = false;

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void jumpTo(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pc.hasClients) pc.jumpToPage(i);
    });
  }

  Future<void> deleteCurrent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_photo_q')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('no'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('yes'))),
        ],
      ),
    );
    if (ok != true) return;
    final ph = photos[index];
    await AppDb.deletePhoto(ph['id'] as int);
    await PhotoStore.remove(ph['file'] as String);
    if (!mounted) return;
    setState(() {
      photos.removeAt(index);
      if (index >= photos.length) index = photos.length - 1;
      zoomed = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t('photo_deleted'))));
    if (photos.isEmpty) {
      Navigator.pop(context);
      return;
    }
    jumpTo(index);
  }

  Future<void> makeMain() async {
    final ph = photos[index];
    await AppDb.makeMain(widget.profileId, ph['id'] as int);
    if (!mounted) return;
    setState(() {
      final item = photos.removeAt(index);
      photos.insert(0, item);
      index = 0;
      zoomed = false;
    });
    jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${index + 1} / ${photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: t('set_main'),
            onPressed: index == 0 ? null : makeMain,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: t('delete'),
            onPressed: deleteCurrent,
          ),
        ],
      ),
      body: PageView.builder(
        controller: pc,
        physics: zoomed ? const NeverScrollableScrollPhysics() : null,
        itemCount: photos.length,
        onPageChanged: (i) => setState(() {
          index = i;
          zoomed = false;
        }),
        itemBuilder: (context, i) => _ZoomPage(
          key: ValueKey(photos[i]['id']),
          file: photos[i]['file'] as String,
          onZoom: (z) {
            if (z != zoomed) setState(() => zoomed = z);
          },
        ),
      ),
    );
  }
}

class _ZoomPage extends StatefulWidget {
  final String file;
  final ValueChanged<bool> onZoom;
  const _ZoomPage({super.key, required this.file, required this.onZoom});
  @override
  State<_ZoomPage> createState() => _ZoomPageState();
}

class _ZoomPageState extends State<_ZoomPage> {
  final tc = TransformationController();

  @override
  void dispose() {
    tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: tc,
      minScale: 1,
      maxScale: 5,
      onInteractionEnd: (_) =>
          widget.onZoom(tc.value.getMaxScaleOnAxis() > 1.01),
      child: Center(
        child: StoredImage(widget.file, fit: BoxFit.contain),
      ),
    );
  }
}
