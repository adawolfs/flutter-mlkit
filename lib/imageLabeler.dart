import 'dart:ui';

abstract class ImageLabeler {
  Future loadModel();
  void setImage(img);
  Future run();
  getPrediction();
}
