import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  final String sessionId;
  final String storeId;
  final String storeName;
  final String area;
  final String aisle;
  final String segment;

  const CameraScreen({
    super.key,
    required this.sessionId,
    required this.storeId,
    required this.storeName,
    required this.area,
    required this.aisle,
    required this.segment,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _captureCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/${widget.sessionId}_$timestamp.jpg';
      
      final image = await _controller!.takePicture();
      await File(image.path).copy(filePath);
      
      // Save to database with FULL metadata
      await _db.insertImageCapture(
        sessionId: widget.sessionId,
        storeId: widget.storeId,
        storeName: widget.storeName,
        area: widget.area,
        aisle: widget.aisle,
        segment: widget.segment,
        captureType: 'label',
        filePath: filePath,
      );
      
      setState(() {
        _captureCount++;
        _isCapturing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Captured image #$_captureCount - ${widget.area}/${widget.aisle}/${widget.segment}')),
      );
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.area} - ${widget.aisle} - ${widget.segment}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isInitialized
          ? Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Captured: $_captureCount',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          onPressed: _captureImage,
                          backgroundColor: _isCapturing ? Colors.grey : Colors.blue,
                          child: _isCapturing ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.camera),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
