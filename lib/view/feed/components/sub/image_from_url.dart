import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageFromUrl extends StatelessWidget {
  final String imageUrl;

  ImageFromUrl({@required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const Icon(Icons.broken_image);
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        fit: BoxFit.cover,
      );
      //   TransitionToImage(
      //   image: AdvancedNetworkImage(
      //     imageUrl,
      //     useDiskCache: true,
      //   ),
      //   placeholder: const Icon(Icons.broken_image),
      //   fit: BoxFit.cover,
      // );
    }
  }
}
