part of '../../pages/blog_services/blog_preview.dart';

class _XhrImage extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const _XhrImage({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<_XhrImage> createState() => _XhrImageState();
}

class _XhrImageState extends State<_XhrImage> {
  String?    _svgString;
  Uint8List? _rasterBytes;
  bool _isSvg  = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _XhrImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _svgString   = null;
      _rasterBytes = null;
      _isSvg  = false;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final xhr = html.HttpRequest();
      xhr.open('GET', widget.url, async: true);
      xhr.responseType = 'arraybuffer';

      final completer = Completer<Uint8List>();

      xhr.onLoad.listen((_) {
        if (xhr.status == 200) {
          final buf = xhr.response as ByteBuffer;
          completer.complete(buf.asUint8List());
        } else {
          completer.completeError('HTTP ${xhr.status}');
        }
      });
      xhr.onError.listen((_) => completer.completeError('XHR error'));
      xhr.send();

      final bytes = await completer.future;
      final header = String.fromCharCodes(bytes.take(20));

      if (header.trimLeft().startsWith('<svg') ||
          header.trimLeft().startsWith('<?xml')) {
        final svgStr = String.fromCharCodes(bytes);
        if (mounted) {
          setState(() {
            _svgString = svgStr;
            _isSvg = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _rasterBytes = bytes;
            _isSvg = false;
          });
        }
      }
    } catch (e) {
      debugPrint('_XhrImage load error: $e | url: ${widget.url}');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        width: widget.width, height: widget.height,
        color: ColorPick.background,
        child: Icon(Icons.broken_image_outlined,
            size: 24.sp, color: AppColors.secondaryText),
      );
    }

    if (_svgString == null && _rasterBytes == null) {
      return SizedBox(
        width: widget.width, height: widget.height,
        child: const Center(
          child: CircleProgress(),
        ),
      );
    }

    if (_isSvg && _svgString != null) {
      return SizedBox(
        width: widget.width, height: widget.height,
        child: Center(
          child: SvgPicture.string(
            _svgString!,
            width:  widget.width  * 0.5,
            height: widget.height * 0.5,
            fit: BoxFit.scaleDown,
          ),
        ),
      );
    }

    if (_rasterBytes != null) {
      return Image.memory(
        _rasterBytes!,
        width:  widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: widget.width, height: widget.height,
          color: ColorPick.background,
          child: Icon(Icons.broken_image_outlined,
              size: 24.sp, color: AppColors.secondaryText),
        ),
      );
    }

    return Container(
      width: widget.width, height: widget.height,
      color: ColorPick.white,
      child: Icon(Icons.image_outlined,
          size: 24.sp, color: AppColors.secondaryText),
    );
  }
}
