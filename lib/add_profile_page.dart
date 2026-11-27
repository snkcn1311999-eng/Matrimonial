import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'common.dart';
import 'db.dart';
import 'photo_store.dart';

class AddProfilePage extends StatefulWidget {
  const AddProfilePage({super.key});
  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  final _form = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final mobileC = TextEditingController();
  final heightC = TextEditingController();
  final religionC = TextEditingController();
  final casteC = TextEditingController();
  final districtC = TextEditingController();
  final educationC = TextEditingController();
  final professionC = TextEditingController();
  final notesC = TextEditingController();

  // Assets & financial details
  final totalAssetsC = TextEditingController();
  final housesC = TextEditingController();
  final houseLocC = TextEditingController();
  final rentC = TextEditingController();
  final landDetailsC = TextEditingController();
  final landValueC = TextEditingController();
  final vehiclesC = TextEditingController();
  final otherAssetsC = TextEditingController();
  final extraFinC = TextEditingController();
  String? ownHouse;
  String? agriLand;
  String? commercial;

  String? gender;
  DateTime? dob;
  String marital = 'unmarried';
  String status = 'active';
  bool saving = false;
  final List<XFile> picked = [];

  @override
  void dispose() {
    for (final c in [
      nameC, mobileC, heightC, religionC, casteC,
      districtC, educationC, professionC, notesC,
      totalAssetsC, housesC, houseLocC, rentC, landDetailsC,
      landValueC, vehiclesC, otherAssetsC, extraFinC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickPhotos() async {
    final files = await PhotoStore.pick();
    if (files.isNotEmpty) setState(() => picked.addAll(files));
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: t('pick_dob'),
    );
    if (d != null) setState(() => dob = d);
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    if (gender == null || dob == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('select_gender_dob'))));
      return;
    }
    final mobile = mobileC.text.trim();
    final dup = await AppDb.findByMobile(mobile);
    if (dup != null) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t('duplicate')),
          content: Text('${dup['name']} (${dup['profile_id']})'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t('cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t('save_anyway'))),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => saving = true);
    final id = await AppDb.insert({
      'name': nameC.text.trim(),
      'gender': gender,
      'dob': dob!.toIso8601String().substring(0, 10),
      'mobile': mobile,
      'district': districtC.text.trim(),
      'status': status,
      'data': jsonEncode({
        'height': heightC.text.trim(),
        'marital': marital,
        'religion': religionC.text.trim(),
        'caste': casteC.text.trim(),
        'education': educationC.text.trim(),
        'profession': professionC.text.trim(),
        'notes': notesC.text.trim(),
        'total_assets': totalAssetsC.text.trim(),
        'houses_count': housesC.text.trim(),
        'own_house': ownHouse ?? '',
        'house_location': houseLocC.text.trim(),
        'rental_income': rentC.text.trim(),
        'land_details': landDetailsC.text.trim(),
        'land_value': landValueC.text.trim(),
        'agri_land': agriLand ?? '',
        'commercial': commercial ?? '',
        'vehicles': vehiclesC.text.trim(),
        'other_assets': otherAssetsC.text.trim(),
        'extra_finance': extraFinC.text.trim(),
      }),
    });
    for (final x in picked) {
      final name = await PhotoStore.save(x);
      await AppDb.addPhoto(id, name);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t('saved'))));
    Navigator.pop(context);
  }

  Widget field(TextEditingController c, String key,
      {TextInputType? type, bool req = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: t(key) + (req ? ' *' : ''),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: req
            ? (v) => (v == null || v.trim().isEmpty) ? t('required') : null
            : null,
      ),
    );
  }

  Widget label(String key) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(t(key),
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: maroon)),
      );

  Widget sectionTitle(String key) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Text(t(key),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: maroon)),
      );

  Widget chips(List<String> keys, String? selected, void Function(String) on) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: keys
            .map((k) => ChoiceChip(
                  label: Text(t(k), style: const TextStyle(fontSize: 15)),
                  selected: selected == k,
                  selectedColor: gold,
                  onSelected: (_) => setState(() => on(k)),
                ))
            .toList(),
      ),
    );
  }

  Widget yesNo(String labelKey, String? value, void Function(String) on) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(labelKey),
        chips(['yes', 'no'], value, on),
      ],
    );
  }

  Widget photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('photos'),
        if (picked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < picked.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(picked[i].path),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            cacheWidth: 270),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => picked.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: maroon, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 16, color: cream),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.white,
            foregroundColor: maroon,
            side: const BorderSide(color: gold),
          ),
          icon: const Icon(Icons.add_a_photo),
          label: Text(t('add_photos')),
          onPressed: pickPhotos,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = dob == null
        ? null
        : ageFromDob(dob!.toIso8601String().substring(0, 10));
    return Scaffold(
      appBar: AppBar(title: Text(t('add'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t('personal'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: maroon)),
            const SizedBox(height: 12),
            photoSection(),
            field(nameC, 'name', req: true),
            label('gender'),
            chips(['male', 'female'], gender, (v) => gender = v),
            label('dob'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  alignment: Alignment.centerLeft,
                ),
                icon: const Icon(Icons.calendar_today, color: maroon),
                label: Text(dob == null
                    ? t('pick_dob')
                    : '${showDate(dob!.toIso8601String())}   (${t('age')}: $age)'),
                onPressed: pickDob,
              ),
            ),
            field(heightC, 'height', type: TextInputType.number),
            label('marital'),
            chips(['unmarried', 'divorced', 'widowed'], marital,
                (v) => marital = v),
            field(religionC, 'religion'),
            field(casteC, 'caste'),
            field(districtC, 'district'),
            field(educationC, 'education'),
            field(professionC, 'profession'),
            TextFormField(
              controller: mobileC,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: '${t('mobile')} *',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return t('required');
                if (!RegExp(r'^[0-9]{10}$').hasMatch(s)) {
                  return t('invalid_mobile');
                }
                return null;
              },
            ),
            const Divider(height: 32),
            sectionTitle('assets_title'),
            field(totalAssetsC, 'total_assets', type: TextInputType.number),
            field(housesC, 'houses_count', type: TextInputType.number),
            yesNo('own_house', ownHouse, (v) => ownHouse = v),
            field(houseLocC, 'house_location'),
            field(rentC, 'rental_income', type: TextInputType.number),
            field(landDetailsC, 'land_details', lines: 2),
            field(landValueC, 'land_value', type: TextInputType.number),
            yesNo('agri_land', agriLand, (v) => agriLand = v),
            yesNo('commercial', commercial, (v) => commercial = v),
            field(vehiclesC, 'vehicles'),
            field(otherAssetsC, 'other_assets', lines: 2),
            field(extraFinC, 'extra_finance', lines: 2),
            const Divider(height: 32),
            label('status'),
            chips(['active', 'pending', 'married'], status, (v) => status = v),
            field(notesC, 'notes', lines: 3),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(t('save')),
              onPressed: saving ? null : save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
