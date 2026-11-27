import 'package:flutter/material.dart';
import 'strings_photos.dart';

const maroon = Color(0xFF800000);
const cream = Color(0xFFFFF8E7);
const gold = Color(0xFFC9A227);

// Default language: 'ta' = Tamil, 'en' = English
final ValueNotifier<String> langNotifier = ValueNotifier<String>('ta');

String t(String key) =>
    strings[langNotifier.value]?[key] ??
    photoStrings[langNotifier.value]?[key] ??
    key;

int? ageFromDob(String? dob) {
  if (dob == null || dob.isEmpty) return null;
  final d = DateTime.tryParse(dob);
  if (d == null) return null;
  final n = DateTime.now();
  var a = n.year - d.year;
  if (n.month < d.month || (n.month == d.month && n.day < d.day)) a--;
  return a;
}

String showDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}

const Map<String, Map<String, String>> strings = {
  'en': {
    'title': 'Matrimonial Office',
    'total': 'Total Profiles',
    'male': 'Male',
    'female': 'Female',
    'newly': 'Newly Added',
    'married': 'Married',
    'pending': 'Pending',
    'active': 'Active',
    'add': 'Add New Profile',
    'view': 'View All Profiles',
    'search': 'Search Profile',
    'recent': 'Recently Added',
    'settings': 'Settings',
    'soon': 'Coming soon',
    'language': 'தமிழ்',
    'personal': 'Personal Details',
    'name': 'Full Name',
    'gender': 'Gender',
    'dob': 'Date of Birth',
    'age': 'Age',
    'height': 'Height (cm)',
    'marital': 'Marital Status',
    'unmarried': 'Never Married',
    'divorced': 'Divorced',
    'widowed': 'Widowed',
    'religion': 'Religion',
    'caste': 'Caste',
    'district': 'District',
    'mobile': 'Mobile Number',
    'education': 'Education',
    'profession': 'Profession',
    'status': 'Profile Status',
    'notes': 'Admin Notes',
    'save': 'Save',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'delete': 'Delete',
    'required': 'Required',
    'invalid_mobile': 'Enter a 10 digit number',
    'pick_dob': 'Select date',
    'select_gender_dob': 'Please select gender and date of birth',
    'saved': 'Profile saved',
    'duplicate': 'This mobile number already exists',
    'save_anyway': 'Save anyway',
    'no_profiles': 'No profiles found',
    'confirm_delete': 'Delete this profile?',
    'yes': 'Yes',
    'no': 'No',
    'profile_id': 'Profile ID',
    'search_hint': 'Name, Profile ID or Mobile',
    'deleted': 'Profile deleted',
    'years': 'yrs',
  },
  'ta': {
    'title': 'திருமண தகவல் மையம்',
    'total': 'மொத்த விவரங்கள்',
    'male': 'ஆண்',
    'female': 'பெண்',
    'newly': 'புதியவை',
    'married': 'திருமணமானது',
    'pending': 'நிலுவையில்',
    'active': 'செயலில்',
    'add': 'புதிய விவரம் சேர்க்க',
    'view': 'விவரங்களை பார்க்க',
    'search': 'தேடுக',
    'recent': 'சமீபத்தில் சேர்த்தவை',
    'settings': 'அமைப்புகள்',
    'soon': 'விரைவில்',
    'language': 'English',
    'personal': 'தனிப்பட்ட விவரங்கள்',
    'name': 'முழு பெயர்',
    'gender': 'பாலினம்',
    'dob': 'பிறந்த தேதி',
    'age': 'வயது',
    'height': 'உயரம் (செ.மீ)',
    'marital': 'திருமண நிலை',
    'unmarried': 'திருமணமாகாதவர்',
    'divorced': 'விவாகரத்தானவர்',
    'widowed': 'துணையை இழந்தவர்',
    'religion': 'மதம்',
    'caste': 'சாதி',
    'district': 'மாவட்டம்',
    'mobile': 'கைபேசி எண்',
    'education': 'கல்வி',
    'profession': 'தொழில்',
    'status': 'விவர நிலை',
    'notes': 'குறிப்புகள்',
    'save': 'சேமி',
    'cancel': 'ரத்து',
    'edit': 'திருத்து',
    'delete': 'நீக்கு',
    'required': 'அவசியம்',
    'invalid_mobile': '10 இலக்க எண்ணை உள்ளிடவும்',
    'pick_dob': 'தேதியை தேர்ந்தெடுக்கவும்',
    'select_gender_dob': 'பாலினம் மற்றும் பிறந்த தேதியை தேர்ந்தெடுக்கவும்',
    'saved': 'சேமிக்கப்பட்டது',
    'duplicate': 'இந்த கைபேசி எண் ஏற்கனவே உள்ளது',
    'save_anyway': 'இருந்தாலும் சேமி',
    'no_profiles': 'விவரங்கள் எதுவும் இல்லை',
    'confirm_delete': 'இந்த விவரத்தை நீக்கவா?',
    'yes': 'ஆம்',
    'no': 'இல்லை',
    'profile_id': 'விவர எண்',
    'search_hint': 'பெயர், விவர எண் அல்லது கைபேசி',
    'deleted': 'நீக்கப்பட்டது',
    'years': 'வயது',
  },
};
