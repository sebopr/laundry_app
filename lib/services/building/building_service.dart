import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

/// An address from the federal building register (GWR) search.
class AddressSuggestion {
  /// `<EGID>_<EDID>` — identifies the building and its entrance.
  final String featureId;
  final String label;

  const AddressSuggestion({required this.featureId, required this.label});
}

/// Thrown by [BuildingService.createBuilding] with the Cloud Function's
/// error code, so the page can show a matching message.
class BuildingException implements Exception {
  final String code;
  final String? message;
  const BuildingException(this.code, this.message);

  @override
  String toString() => message ?? code;
}

/// Building administration. Creating buildings, listing and removing
/// residents all run as Cloud Functions (functions/src/buildings.ts) so the
/// admin trust rules — one building and names only until verified — are
/// enforced server-side.
class BuildingService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west6');

  /// Searches Swiss building addresses via swisstopo's public search.
  static Future<List<AddressSuggestion>> searchAddresses(String query) async {
    final uri = Uri.https(
      'api3.geo.admin.ch',
      '/rest/services/api/SearchServer',
      {
        'searchText': query,
        'type': 'locations',
        'origins': 'address',
        'limit': '8',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Address search failed (${res.statusCode})');
    }
    final results = (jsonDecode(res.body)['results'] as List?) ?? [];
    return results
        .map((r) => r['attrs'] as Map<String, dynamic>)
        .where((a) => a['featureId'] != null)
        .map((a) => AddressSuggestion(
              featureId: a['featureId'] as String,
              // Labels come with <b> around the postcode and town.
              label: (a['label'] as String).replaceAll(RegExp(r'<[^>]*>'), ''),
            ))
        .toList();
  }

  /// Creates a building for the current admin. Returns its id and name.
  static Future<({String id, String name})> createBuilding(
      String featureId) async {
    try {
      final result = await _functions.httpsCallable('createBuilding').call({
        'featureId': featureId,
        'declarationAccepted': true,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return (id: data['buildingId'] as String, name: data['name'] as String);
    } on FirebaseFunctionsException catch (e) {
      throw BuildingException(e.code, e.message);
    }
  }

  /// Residents of a building the caller administers. `email` is only
  /// present when the admin is verified.
  static Future<List<Map<String, dynamic>>> getResidents(
      String buildingId) async {
    try {
      final result = await _functions
          .httpsCallable('getBuildingResidents')
          .call({'buildingId': buildingId});
      final data = Map<String, dynamic>.from(result.data as Map);
      return (data['residents'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// Removes a resident from a building the caller administers. Their
  /// household membership and future bookings are cleaned up too.
  static Future<void> removeResident(String buildingId, String uid) async {
    try {
      await _functions
          .httpsCallable('removeResident')
          .call({'buildingId': buildingId, 'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// Reports the caller's building admin as not acting for the owner.
  static Future<void> reportAdmin(String reason) async {
    try {
      await _functions
          .httpsCallable('reportBuildingAdmin')
          .call({'reason': reason});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }
}
