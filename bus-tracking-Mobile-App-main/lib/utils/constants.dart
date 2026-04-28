import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// ============================================================
// Configuration Backend - Base de données PostgreSQL via Spring Boot
// ============================================================
//
// Architecture :
//   [Flutter App] --> HTTP --> [Spring Boot :8081] --> [PostgreSQL :5432]
//
// URLs selon la plateforme :
//   • Émulateur Android  : http://10.0.2.2:8081/Bus-tracking
//     (10.0.2.2 = alias Android vers localhost de la machine hôte)
//   • Appareil physique  : http://<IP_DE_VOTRE_PC>:8081/Bus-tracking
//     (ex: http://192.168.1.100:8081/Bus-tracking)
//   • Web / Desktop      : http://localhost:8081/Bus-tracking
//
// Pour trouver votre IP locale : ipconfig (Windows) → IPv4 de votre réseau Wi-Fi
// ============================================================

/// IP de votre PC sur le réseau local (pour appareil physique)
/// Modifiez cette valeur si vous testez sur un vrai téléphone !
const String kHostIp = '192.168.1.100';

String get kBackendBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:8081/Bus-tracking';
  }
  try {
    if (Platform.isAndroid) {
      // 10.0.2.2 = localhost de la machine hôte depuis l'émulateur Android
      return 'http://10.0.2.2:8081/Bus-tracking';
    } else if (Platform.isIOS) {
      // Sur iOS simulateur, localhost fonctionne directement
      return 'http://localhost:8081/Bus-tracking';
    }
  } catch (_) {}
  return 'http://localhost:8081/Bus-tracking';
}

// Colors
const kBackgroundColor = Color(0xFFD2FFF4);
const kPrimaryColor = Color(0xFF2D5D70);
const kSecondaryColor = Color(0xFF265DAB);
const Color kInputFieldFillColor = Colors.white;
