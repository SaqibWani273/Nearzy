import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class LargeSlidingImagesWidget extends StatelessWidget {
  final List<String> slidingImages;
  final double? height;
  final String? title;
  final Widget? button;
  const LargeSlidingImagesWidget({
    required this.slidingImages,
    this.title,
    this.height,
    super.key,
    this.button,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      // height: widget.height,
      child: title == null
          ? ImagesWidget(slidingImages: slidingImages)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ImagesWidget(
                  slidingImages: slidingImages,
                  button: button,
                ),
              ],
            ),
    );
  }
}

class ImagesWidget extends StatefulWidget {
  final List<String> slidingImages;
  final Color? indicatorColor;
  final double? indicatorWidth;
  final Widget? button;
  const ImagesWidget({
    super.key,
    required this.slidingImages,
    this.indicatorColor = Colors.blue,
    this.indicatorWidth = 15.0,
    this.button,
  });

  @override
  State<ImagesWidget> createState() => _ImagesWidgetState();
}

class _ImagesWidgetState extends State<ImagesWidget> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      CarouselSlider(
        options: CarouselOptions(
          // height: widget.height,
          aspectRatio: 16 / 12,
          //add these two to stop scroll after last image
          enableInfiniteScroll: false,
          padEnds: false,

          viewportFraction: 1.0,
          onPageChanged: (index, reason) => setState(() {
            currentIndex = index;
          }),
        ),
        items: widget.slidingImages
            .map(
              (imageUrl) => SizedBox(
                width: double.infinity,
                child:
                    // SvgPicture.asset(
                    //   imageUrl,
                    //   // semanticsLabel: 'Acme Logo'
                    // ),
                    Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.fill,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) {
                      return Container(
                        color: Colors.grey.withValues(alpha: 0.5),
                      );
                    }
                    return child;
                  },
                ),
              ),
            )
            .toList(),
      ),
      if (widget.slidingImages.length > 1)
        Positioned(
          bottom: 5,
          child: SizedBox(
            //  height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: widget.slidingImages.asMap().entries.map((entry) {
                return Container(
                  width: widget.indicatorWidth,
                  height: widget.indicatorWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),

                    // borderRadius: BorderRadius.circular(
                    //     currentIndex == entry.key ? 8 : 15),
                    color: currentIndex == entry.key
                        ? widget.indicatorColor
                        : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      if (widget.button != null)
        Positioned(
          bottom: 45,
          child: SizedBox(
              //  height: 45,
              child: Center(child: widget.button)),
        ),
    ]);
  }
}
