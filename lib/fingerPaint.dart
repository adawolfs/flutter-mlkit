import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io' as Io;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter_mlkit/tflite/mnist.dart';
import 'package:flutter_android/android_graphics.dart' show Bitmap;

const directoryName = 'Signature';

class FingerPaint extends StatefulWidget {
  FingerPaint({Key key}) : super(key: key);
  TFLiteMIST labeler;
  _FingerPaintState fps;

  clean() {
    print("clean");
    fps.clearPoints();
  }

  @override
  State<StatefulWidget> createState() {
    labeler = TFLiteMIST();
    labeler.loadModel();
    fps = _FingerPaintState();
    return fps;
  }
}

class _FingerPaintState extends State<FingerPaint> {
  // _points stores the path drawn which is passed to
  List<Offset> _points = <Offset>[];

  Future<ui.Image> get rendered {
    // [CustomPainter] has its own @canvas to pass our
    // [ui.PictureRecorder] object must be passed to [Canvas]#contructor
    // to capture the Image. This way we can pass @recorder to [Canvas]#contructor
    // using @painter[SignaturePainter] we can call [SignaturePainter]#paint
    // with the our newly created @canvas
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    FingerPainter painter = FingerPainter(points: _points);
    var size = context.size;
    painter.paint(canvas, size);
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  ui.Image image;
  Permission _permission = Permission.WriteExternalStorage;
  requestPermission() async {
    final result = await SimplePermissions.requestPermission(_permission);
    return result;
  }

  checkPermission() async {
    bool result = await SimplePermissions.checkPermission(_permission);
    return result;
  }

  getPermissionStatus() async {
    final result = await SimplePermissions.getPermissionStatus(_permission);
    print("permission status is " + result.toString());
  }

  String formattedDate() {
    DateTime dateTime = DateTime.now();
    String dateTimeString = 'Signature_' +
        dateTime.year.toString() +
        dateTime.month.toString() +
        dateTime.day.toString() +
        dateTime.hour.toString() +
        ':' +
        dateTime.minute.toString() +
        ':' +
        dateTime.second.toString() +
        ':' +
        dateTime.millisecond.toString() +
        ':' +
        dateTime.microsecond.toString();
    return dateTimeString;
  }

  Future<Null> detectImage(BuildContext context) async {
    ui.Image tmpImage = await rendered;
    await widget.labeler.setImage(tmpImage);
    await widget.labeler.run();
    var result = widget.labeler.getPrediction();

    final snackBar = SnackBar(
      content: Text(result[0].toString()),
    );

    // Find the Scaffold in the Widget tree and use it to show a SnackBar!
    Scaffold.of(context).showSnackBar(snackBar);
  }

  // Not used

  Future<String> showImage(BuildContext context, image) async {
    // print(await checkPermission());
    // //image = await rendered;

    // //var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    // if (!(await checkPermission())) {
    //   print('request permision');
    //   await requestPermission();
    // }
    // // Use plugin [path_provider] to export image to storage
    // Directory directory = await getExternalStorageDirectory();
    // String path = directory.path;
    // await Directory('$path/$directoryName').create(recursive: true);
    // var fullPath = '$path/$directoryName/${formattedDate()}.png';
    // print(fullPath);
    // File(fullPath).writeAsBytesSync(image);

    showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Please check your device\'s Signature folder',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w300,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.1),
            ),
            content: Image.memory(img
                .decodeImage(new Io.File(
                        "/storage/emulated/0/Signature/Signature_20194111:29:2:979:722.png")
                    .readAsBytesSync())
                .getBytes()),
            //content: Image.memory(Uint8List.view(image)),
            //content: Image.memory(Uint8List.view(pngBytes.buffer)),
          );
        });
    return "/storage/emulated/0/Signature/Signature_20194111:29:2:979:722.png";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(width: 100.0, height: 100.0),
      decoration:
          new BoxDecoration(border: new Border.all(color: Colors.blueAccent)),
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            RenderBox _object = context.findRenderObject();
            Offset _locationPoints =
                _object.globalToLocal(details.globalPosition);
            print(_locationPoints);

            // need to find a native way to avoid points to go outside borders
            if (_locationPoints.dx > 0 &&
                _locationPoints.dy > 0 &&
                _locationPoints.dx < 100 &&
                _locationPoints.dy < 100) {
              _points = new List.from(_points)..add(_locationPoints);
            }
          });
        },
        onPanEnd: (DragEndDetails details) {
          detectImage(context);
          setState(() {
            _points.add(null);
          });
        },
        child: CustomPaint(
          painter: FingerPainter(points: _points),
        ),
      ),
    );
  }

  // clearPoints method used to reset the canvas
  // method can be called using
  //   key.currentState.clearPoints();
  void clearPoints() {
    setState(() {
      _points.clear();
    });
  }
}

class FingerPainter extends CustomPainter {
  // [FingerPainter] receives points through constructor
  // @points holds the drawn path in the form (x,y) offset;
  // This class responsible for drawing only
  // It won't receive any drag/touch events by draw/user.
  List<Offset> points = <Offset>[];

  FingerPainter({this.points});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(FingerPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
