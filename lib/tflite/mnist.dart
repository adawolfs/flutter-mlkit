import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_mlkit/imageLabeler.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;

class TFLiteMIST implements ImageLabeler {
  img.Image imageByteData;
  var result;

  @override
  Future loadModel() async {
    Tflite.loadModel(
      model: "assets/tf/mnist.tflite",
      labels: "assets/tf/mnist.txt",
    );
  }

  @override
  void setImage(i) async {
    ByteData tmpImageBytes = await i.toByteData(format: ui.ImageByteFormat.png);
    img.Image oriImage = img.decodePng(tmpImageBytes.buffer.asUint8List());
    img.Image resizedImage = img.copyResize(oriImage, 28, 28);
    // Uint8List bytes = imageByteData.getBytes();
    // img.Image oriImage = img.decodeJpg(bytes);
    this.imageByteData = resizedImage;
  }

  @override
  Future run() async {
    var recognitions = await Tflite.runModelOnBinary(
      binary: imageToByteListFloat32(this.imageByteData, 28),
    );
    print("RECORN");
    print(recognitions);
    result = recognitions;
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize - 1; i++) {
      for (var j = 0; j < inputSize - 1; j++) {
        var pixel = image.getPixel(j, i);
        print("$i:$j -> $pixel");
        var npixel = convertPixel(0 - pixel);
        print("$i:$j -> $npixel");
        buffer[pixelIndex++] = npixel;
      }
    }
    print(convertedBytes.buffer);
    //print(convertedBytes.buffer.asUint8List());
    return convertedBytes.buffer.asUint8List();
  }

  double convertPixel(int rgb) {
    var color = (rgb ~/ 255);
    print(color);
    if (color == 0) return 0;
    return 0 -
        ((255 -
                (((color >> 16) & 0xFF) * 0.299 +
                    ((color >> 8) & 0xFF) * 0.587 +
                    (color & 0xFF) * 0.114)) /
            255.0);
  }

  @override
  getPrediction() {
    return this.result;
  }

  getImage() {}
}
