import 'package:flutter/material.dart';
import '../services/favorite_repository.dart';

class FavoriteProvider with ChangeNotifier {
  List<String> _favorites = [];

  List<String> get favorites => _favorites;

  Future<void> loadFavorites({required bool isGuest, user}) async {
    _favorites =
        await FavoriteRepository.getFavorites(isGuest: isGuest, user: user);
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id,
      {required bool isGuest, required user}) async {
    if (isFavorite(id)) {
      await FavoriteRepository.removeFavorite(id, isGuest: isGuest, user: user);
      _favorites.remove(id);
    } else {
      await FavoriteRepository.addFavorite(id, isGuest: isGuest, user: user);
      _favorites.add(id);
    }
    notifyListeners();
  }

  Future<void> remove(String id, {required bool isGuest, user}) async {
    await FavoriteRepository.removeFavorite(id, isGuest: isGuest, user: user);
    _favorites.remove(id);
    notifyListeners();
  }

  Future<void> add(String id, {required bool isGuest, user}) async {
    await FavoriteRepository.addFavorite(id, isGuest: isGuest, user: user);
    if (!_favorites.contains(id)) {
      _favorites.add(id);
      notifyListeners();
    }
  }
}
