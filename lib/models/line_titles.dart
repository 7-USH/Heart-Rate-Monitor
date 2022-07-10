// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heart_rate_app/constants/constants.dart';

class LineTitles {
  static getTitleData() => FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            margin: 12,
            getTextStyles: (v) =>
                appText(color: Colors.white60, weight: FontWeight.w500),
            getTitles: (v) {
              switch (v.toInt()) {
                case 1:
                  return "2";
                case 2:
                  return '4';
                case 3:
                  return '6';
                case 4:
                  return '8';
                case 5:
                  return '10';
                case 6:
                  return '12';
                case 7:
                  return '14';
                case 8:
                  return '16';
              }
              return "";
            }),
        leftTitles: SideTitles(
            showTitles: true,
            margin: 12,
            reservedSize: 38,
            getTextStyles: (v) =>
                appText(color: Colors.white60, weight: FontWeight.w500),
            getTitles: (v) {
              switch (v.toInt()) {
                case 1:
                  return "50";
                case 2:
                  return '100';
                case 3:
                  return '150';
                case 4:
                  return '200';
                case 5:
                  return '250';
                case 6:
                  return '300';
              }
              return "";
            }),
      );
}
