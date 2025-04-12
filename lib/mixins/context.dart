import 'package:flutter/material.dart';

mixin ContextValuesMixin<T extends StatefulWidget> on State<T>{
  ThemeData get theme_=>Theme.of(context);
  TextTheme? get textTheme_=> theme_.textTheme;
  ColorScheme? get colorScheme_=>theme_.colorScheme;
  Size get mediaSize_=>MediaQuery.sizeOf(context);
}