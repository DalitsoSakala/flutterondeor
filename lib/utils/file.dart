import 'dart:io';

class UtilFile{
  final File ref;
  final String? filename;
  /// Use if using with a form
  final String? formField;

  UtilFile({required this.ref, this.filename, this.formField});
  Future<int> get length=>ref.length();
}