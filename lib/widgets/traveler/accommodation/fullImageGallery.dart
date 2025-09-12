import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullImageGallery extends StatelessWidget {
  final List<String> images;

  const FullImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF244B6B), // ✅ Fond bleu foncé
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // ✅ Bouton retour
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Gallery",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), // ✅ Coins arrondis
              child: GestureDetector(
                onTap: () {
                  // 🚀 Ouvrir la photo en plein écran avec zoom
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _FullScreenImageViewer(
                          images: images, initialIndex: index),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.white,
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ), // ✅ Shimmer au lieu du loader circulaire
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 📌 Affichage plein écran avec zoom
class _FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer(
      {required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close,
                  color: Colors.white, size: 30), // ✅ Bouton retour en haut
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
