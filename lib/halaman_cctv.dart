import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'layanan_cctv.dart';

class CctvPage extends StatefulWidget {
  final List<CctvLocation> cctvLocations;
  final int initialIndex;

  const CctvPage({
    super.key,
    required this.cctvLocations,
    this.initialIndex = 0,
  });

  @override
  State<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends State<CctvPage> {
  late PageController _videoPageController;
  late PageController _graphPageController;
  int _selectedCctvIndex = 0;
  late List<WebViewController?> _videoControllers;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _suggestionsOverlayEntry;
  List<CctvLocation> _suggestionList = [];

  @override
  void initState() {
    super.initState();
    _selectedCctvIndex = widget.initialIndex;

    _videoPageController = PageController(initialPage: _selectedCctvIndex);
    _graphPageController = PageController(
      initialPage: _selectedCctvIndex,
      viewportFraction: 0.85,
    );
    _videoControllers = List<WebViewController?>.filled(
      widget.cctvLocations.length,
      null,
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
        _showSuggestionsOverlay();
      } else {
        _hideSuggestionsOverlay();
      }
    });
  }

  @override
  void dispose() {
    _videoPageController.dispose();
    _graphPageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _hideSuggestionsOverlay();
    super.dispose();
  }

  void _showSuggestionsOverlay() {
    _suggestionsOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0.0, 55.0),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestionList.length,
                  itemBuilder: (context, index) {
                    final cctv = _suggestionList[index];
                    return ListTile(
                      title: Text(cctv.name),
                      onTap: () => _onSuggestionTapped(cctv),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_suggestionsOverlayEntry!);
  }

  void _hideSuggestionsOverlay() {
    _suggestionsOverlayEntry?.remove();
    _suggestionsOverlayEntry = null;
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestionList = [];
      });
      _hideSuggestionsOverlay();
      return;
    }
    setState(() {
      _suggestionList =
          widget.cctvLocations
              .where(
                (cctv) => cctv.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });

    if (_suggestionsOverlayEntry == null && _searchFocusNode.hasFocus) {
      _showSuggestionsOverlay();
    }
    _suggestionsOverlayEntry?.markNeedsBuild();
  }

  void _onSuggestionTapped(CctvLocation selectedCctv) {
    final index = widget.cctvLocations.indexWhere(
      (cctv) => cctv.streamId == selectedCctv.streamId,
    );
    if (index != -1) {
      _videoPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _initializeControllerIfNeeded(int index) {
    if (widget.cctvLocations.isEmpty) return;
    final cctv = widget.cctvLocations[index];
    if (_videoControllers[index] == null) {
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }
      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(params);
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadRequest(Uri.parse(cctv.streamWebUrl));
      _videoControllers[index] = controller;
    }
  }

  void _onPageChanged(int index) {
    if (_selectedCctvIndex == index) return;
    _graphPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() {
      _selectedCctvIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cctvLocations.isNotEmpty) {
      _initializeControllerIfNeeded(_selectedCctvIndex);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCustomHeader(context),
          const SizedBox(height: 20),
          Expanded(
            child:
                widget.cctvLocations.isEmpty
                    ? const Center(child: Text("Lokasi CCTV tidak ditemukan."))
                    : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSwipableVideoPlayer(),
                          const SizedBox(height: 20),
                          _buildInteractiveGraphSection(),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 50, 10, 20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 96, 80, 167),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                "Live CCTV",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _updateSuggestions,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari nama jalan...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipableVideoPlayer() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _videoPageController,
        itemCount: widget.cctvLocations.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return _buildVideoCard(widget.cctvLocations[index], index);
        },
      ),
    );
  }

  Widget _buildVideoCard(CctvLocation cctv, int index) {
    bool isSelected = index == _selectedCctvIndex;
    if (isSelected) {
      _initializeControllerIfNeeded(index);
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child:
            isSelected && _videoControllers[index] != null
                ? WebViewWidget(controller: _videoControllers[index]!)
                : _buildVideoPlaceholder(cctv),
      ),
    );
  }

  Widget _buildVideoPlaceholder(CctvLocation cctv) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_outlined,
              color: Colors.white60,
              size: 50,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                cctv.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveGraphSection() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _graphPageController,
        itemCount: widget.cctvLocations.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final cctv = widget.cctvLocations[index];
          return AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: _selectedCctvIndex == index ? 1.0 : 0.9,
            child: _buildGraphCard(cctv),
          );
        },
      ),
    );
  }

  Widget _buildGraphCard(CctvLocation cctv) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 239, 239),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cctv.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVehicleCount(
                  "Mobil",
                  cctv.vehicleData.mobil,
                  Icons.directions_car,
                  Colors.blueAccent,
                ),
                _buildVehicleCount(
                  "Motor",
                  cctv.vehicleData.motor,
                  Icons.two_wheeler,
                  Colors.orange,
                ),
                _buildVehicleCount(
                  "Truk",
                  cctv.vehicleData.truk,
                  Icons.local_shipping,
                  Colors.brown,
                ),
                _buildVehicleCount(
                  "Darurat",
                  cctv.vehicleData.darurat,
                  Icons.emergency,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCount(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    const double maxVehicleCount = 50.0;
    final double progress = (count / maxVehicleCount).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(icon, size: 30, color: Colors.grey.shade700),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
