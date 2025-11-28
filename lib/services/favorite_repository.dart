import 'dart:convert';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FavoriteRepository {
  static final String _localKey = 'local_favorites';
  static ApiUrl url = ApiUrl();

  /// 🔄 Récupère les favoris selon mode
  static Future<List<String>> getFavorites(
      {required bool isGuest, dynamic user}) async {
    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_localKey) ?? [];
    } else {
      // 🔐 Appel API (à adapter avec ton endpoint)
      final id = user.id;
      String apiUrl = url.getChicapartsUrl();
      String apiKey = url.getKey();
      final response = await http
          .get(Uri.parse('${apiUrl}me/favourites?user_id=$id'), headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      });
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> favoritesList = decoded['data'];
        return favoritesList
            .map<String>((item) => item['id'].toString())
            .toList();
      } else {
        throw Exception('Erreur de récupération des favoris');
      }
    }
  }

  static Future<List<Stay>> getFavoritesStays(user) async {
    // 🔐 Appel API (à adapter avec ton endpoint)
    final id = user?.id;
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    final response = await http
        .get(Uri.parse('${apiUrl}me/favourites?user_id=$id'), headers: {
      'Accept': 'application/json',
      'X-Authorization': apiKey,
    });
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> favoritesList = decoded['data'];
      return favoritesList.map((data) => Stay.fromJson(data)).toList();
    } else {
      throw Exception('Erreur de récupération des favoris');
    }
  }

  /// ❤️ Ajouter un favori
  static Future<int> addFavorite(String id,
      {required bool isGuest, user}) async {
    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final favs = await getFavorites(isGuest: true);
      if (!favs.contains(id)) {
        favs.add(id);
        prefs.setStringList(_localKey, favs);
      }
      return 200;
    } else {
      // 🔐 Appel API (à adapter avec ton endpoint)
      final uId = user.id.toString();
      String apiUrl = url.getChicapartsUrl();
      String apiKey = url.getKey();
      final response =
          await http.put(Uri.parse('${apiUrl}me/favourites/$id'), headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      }, body: {
        'user_id': uId,
      });

      return response.statusCode;
    }
  }

  /// ❌ Retirer un favori
  static Future<int> removeFavorite(String id,
      {required bool isGuest, dynamic user}) async {
    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final favs = await getFavorites(isGuest: true);
      favs.remove(id);
      prefs.setStringList(_localKey, favs);
      return 200;
    } else {
      final uId = user.id.toString();

      String apiUrl = url.getChicapartsUrl();
      String apiKey = url.getKey();
      final response = await http.put(
        Uri.parse('${apiUrl}me/favourites/$id'),
        headers: {
          'Accept': 'application/json',
          'X-Authorization': apiKey,
        },
        body: {'user_id': uId},
      );
      return response.statusCode;
    }
  }

  /// 🔁 Fusionne favoris locaux dans l’API à la connexion
  static Future<void> syncLocalFavoritesToServer(user) async {
    final prefs = await SharedPreferences.getInstance();
    final localFavs = prefs.getStringList(_localKey) ?? [];

    for (String id in localFavs) {
      await addFavorite(id, isGuest: false, user: user);
    }

    prefs.remove(_localKey); // 🧼 Nettoyer le local après sync
  }
}
