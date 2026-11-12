import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;

class ApiAccommodationTraveler {
  static const Duration _homeCacheTtl = Duration(minutes: 5);
  static List<Destination>? _destinationsCache;
  static DateTime? _destinationsCachedAt;
  static List<Stay>? _popularStaysCache;
  static DateTime? _popularStaysCachedAt;

  List<Destination>? get cachedDestinations => _destinationsCache;
  List<Stay>? get cachedPopularStays => _popularStaysCache;

  bool _isFresh(DateTime? cachedAt) =>
      cachedAt != null && DateTime.now().difference(cachedAt) < _homeCacheTtl;

  Future<List<Destination>> fetchDestinations({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _destinationsCache != null &&
        _isFresh(_destinationsCachedAt)) {
      return _destinationsCache!;
    }
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response =
        await http.get(Uri.parse("${apiUrl}destination"), headers: {
      'Accept': 'application/json',
      'X-Authorization': apiKey,
    });

    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      final destinations =
          jsonResponse.map((data) => Destination.fromJson(data)).toList();
      _destinationsCache = destinations;
      _destinationsCachedAt = DateTime.now();
      return destinations;
    } else {
      throw Exception("Failed to load destinations");
    }
  }

  Future<List<Stay>> fetchStays({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _popularStaysCache != null &&
        _isFresh(_popularStaysCachedAt)) {
      return _popularStaysCache!;
    }
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response =
        await http.get(Uri.parse('${apiUrl}properties/popular'), headers: {
      'Accept': 'application/json',
      'X-Authorization': apiKey,
    });

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> staysData = jsonResponse['data'];
      List<Stay> stays = staysData.map((data) => Stay.fromJson(data)).toList();
      _popularStaysCache = stays;
      _popularStaysCachedAt = DateTime.now();
      return stays;
    } else {
      throw Exception("Failed to load stays");
    }
  }

  Future<List<Stay>> destinationStays(destination) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response = await http
        .get(Uri.parse('${apiUrl}destination/$destination'), headers: {
      'Accept': 'application/json',
      'X-Authorization': apiKey,
    });

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> staysData = jsonResponse['data'];
      List<Stay> stays = staysData.map((data) => Stay.fromJson(data)).toList();
      return stays;
    } else {
      throw Exception("Failed to load stays");
    }
  }

  Future<dynamic> fetchAccommodationDetails(id) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response =
        await http.get(Uri.parse('${apiUrl}properties/$id'), headers: {
      'Accept': 'application/json',
      'X-Authorization': apiKey,
    });
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } else {
      throw Exception("Failed to load stay");
    }
  }

  Future<List<Stay>> fetchFilteredStays(filter) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response = await http.post(Uri.parse('${apiUrl}properties/search'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Authorization': apiKey,
        },
        body: jsonEncode(filter));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> staysData = jsonResponse['data'];
      List<Stay> stays = staysData.map((data) => Stay.fromJson(data)).toList();
      return stays;
    } else {
      throw Exception("Failed to load stays");
    }
  }

  Future<List<Stay>> fetchFavoritesStays(user) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response = await http
        .get(Uri.parse('${apiUrl}me/favourites?user=$user'), headers: {
      'Accept': 'application/json',
      'X-Authorization': apiKey,
    });

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      List<dynamic> staysData = jsonResponse['data'];
      List<Stay> stays = staysData.map((data) => Stay.fromJson(data)).toList();
      return stays;
    } else {
      throw Exception("Failed to load stays");
    }
  }
}
