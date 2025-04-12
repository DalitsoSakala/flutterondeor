import 'package:flutter/material.dart';

(ThemeData,TextTheme,MediaQueryData,Size,bool) valuesOf(BuildContext context){
  final theme=Theme.of(context);
  final media=MediaQuery.of(context);

  return (theme,theme.textTheme,media,MediaQuery.sizeOf(context),theme.brightness==Brightness.dark);
}