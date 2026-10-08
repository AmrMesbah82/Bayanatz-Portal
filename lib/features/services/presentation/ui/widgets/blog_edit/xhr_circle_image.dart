part of '../../pages/blog_services/blog_edit.dart';

class _XhrCircleImage extends StatefulWidget {
  final String url;
  final double size;
  const _XhrCircleImage({required this.url, required this.size});

  @override
  State<_XhrCircleImage> createState() => _XhrCircleImageState();
}

class _XhrCircleImageState extends State<_XhrCircleImage> {
  String? _svgString;
  bool    _failed = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(covariant _XhrCircleImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() { _svgString = null; _failed = false; });
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
          completer.complete((xhr.response as ByteBuffer).asUint8List());
        } else {
          completer.completeError('HTTP ${xhr.status}');
        }
      });
      xhr.onError.listen((_) => completer.completeError('XHR error'));
      xhr.send();
      final bytes = await completer.future;
      if (mounted) setState(() => _svgString = String.fromCharCodes(bytes));
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SizedBox(
        width: widget.size, height: widget.size,
        child: Icon(Icons.broken_image_outlined,
            size: 24.sp, color: AppColors.secondaryText),
      );
    }
    if (_svgString == null) {
      return SizedBox(
        width: widget.size, height: widget.size,
        child: const Center(
          child: CircleProgress(),
        ),
      );
    }
    return SizedBox(
      width: widget.size, height: widget.size,
      child: SvgPicture.string(
        _svgString!,
        width: widget.size, height: widget.size,
        fit: BoxFit.cover,
      ),
    );
  }
}
