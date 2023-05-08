import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:tflite/tflite.dart';

import 'package:screenshot/screenshot.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:nutrition_ai/Utilities/save_image.dart';
import 'package:nutrition_ai/Utilities/share_image.dart';


//import 'package:tensorflow_lite_image_classification/Utilities/toast_dialog.dart';


//TensorFlow Lite (Tflite) Model

class Model extends StatefulWidget {
  const Model({Key? key}) : super(key: key);

  @override
  _ModelState createState() => _ModelState();
}

class _ModelState extends State<Model> {
  Uint8List? bytes;

  final controller = ScreenshotController();

  late File _image;

  //Adjust Width and Height image displayed on the app
  final double _imageWidth = 400.0;
  final double _imageHeight = 400.0;

  late List _results;
  bool imageSelect = false;
  String? _responseBody;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  //Load the Tflite Model

  Future loadModel() async {
    Tflite.close();
    String res;
    res = (await Tflite.loadModel(
        model: "assets/model_final2.tflite",
        labels: "assets/labels_final2.txt"))!;
    print("Models loading status: $res");
  }

  Future imageClassification(File image) async {
    final List? recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _results = recognitions!;
      _image = image;
      imageSelect = true;
    });
  }

  //AppBar
  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("NutriVision", style: TextStyle(
              color: Colors.black, fontStyle: FontStyle.italic, fontSize: 20),),
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          actions: [
            Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.white,
                  iconTheme: const IconThemeData(color: Colors.black),
                ),
                child: PopupMenuButton<int>(
                    color: Colors.white,
                    itemBuilder: (context) =>
                    [
                      PopupMenuItem<int>(
                        value: 0,
                        child: Row(children: const [
                          Icon(
                            Icons.download,
                            color: Colors.black,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text('Save image'),
                        ]),
                        onTap: () async {
                          //saveImage
                          final controller = ScreenshotController();
                          final bytes = await controller.captureFromWidget(
                            Material(child: buildCard()),
                          );
                          await saveImage(bytes);
                        },
                      ),
                      PopupMenuItem<int>(
                        value: 0,
                        child: Row(children: const [
                          Icon(
                            Icons.share,
                            color: Colors.black,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text('Share image'),
                        ]),
                        onTap: () async {
                          //Share function
                          final bytes = await controller.captureFromWidget(
                            Material(child: buildCard()),
                          );
                          /*if (image == null) {
                            return;
                          }*/
                          shareImage(bytes);
                        },
                      ),
                    ])),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            buildCard(),
            if (bytes != null) Image.memory(bytes!),
          ],
        ),

        //App SpeedDial
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          children: [
            SpeedDialChild(
              onTap: _getFromCamera,
              label: 'Take Photo',
              child: const Icon(Icons.camera_alt),
            ),
            SpeedDialChild(
              onTap: pickImage,
              label: 'Pick Image',
              child: const Icon(Icons.image),
            ),
          ],
        ),
      ),
    );
  }

  //Allow app to access device camera feature to take photo
  void _getFromCamera() async {
    final XFile? pickedFile = await ImagePicker()
        .pickImage(
        source: ImageSource.camera,
        maxHeight: 1200,
        maxWidth: 1200,
        imageQuality: 90
    );
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      setState(() {
        File image = File(pickedFile.path);
        imageClassification(image);
        _isUploading = true;
      });
      await uploadImage(image);
    }
  }

  Future pickImageFromCamera(BuildContext context) async {
    await ImagePicker().pickImage(source: ImageSource.camera);
  }

  //Allow app to access device gallery to import a picture into the app
  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1200,
        maxWidth: 1200,
        imageQuality: 90);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      setState(() {
        imageClassification(image);
        _isUploading = true;
      });
      await uploadImage(image);
    }
  }


  Future<void> uploadImage(File imageFile) async {
    // Create a new multipart request
    final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://us-central1-my-project4-377307.cloudfunctions.net/http-test-ocr-2'));

    // Add the image to the request with the key 'image'
    final imageStream = http.ByteStream(imageFile.openRead());
    final imageLength = await imageFile.length();
    final imageMultipart = http.MultipartFile(
        'imagefile', imageStream, imageLength,
        filename: imageFile.path
            .split('/')
            .last);
    request.files.add(imageMultipart);

    // Send the request and get the response
    final response = await http.Response.fromStream(await request.send());

    // Extract and set the response body
    final responseBody = response.body;
    setState(() {
      _responseBody = responseBody;
      _isUploading = false;
    });
  }

  //Display Image Classification class and extracted text by OCR model based on the image displayed on the app UI
  Widget buildCard() =>
      Column(
        children: <Widget>[
          if (_isUploading) ...[
            const CircularProgressIndicator(),
            const Text('Uploading...'),
          ] else
            if (_responseBody != null && _results.isNotEmpty) ...[
              const SizedBox(height: 5),
              if (_results[0]['label'] !=
                  'Unknown') Text( //Check if Tflite class does not display an "Unknown" class on the app
                "${_results[0]['label']}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 30),
              ) else
                const Text(
                  "Unknown Food Item",
                  //Class label show as "Unknown" on the app
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black,
                      fontStyle: FontStyle.italic,
                      fontSize: 20),
                ),
            ],
          (imageSelect)
              ? Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 1),
            child: Image.file(
              _image,
              width: _imageWidth,
              height: _imageHeight,),
          )
              : Center(
            child: Column(
              children: const [
                Padding(padding: EdgeInsets.only(top: 200),
                  child: Icon(Icons.image, size: 200),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    "Please insert an image",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: (imageSelect)
                  ? _results.map((result) {
                return Card(
                  child: Column(
                    children: <Widget>[
                      if (_image != null) ...[
                        if (_isUploading) ...[
                          const CircularProgressIndicator(),
                          const Text('Uploading...'),
                        ] else if (_responseBody != null) ...[
                          const SizedBox(height: 5),
                          if (result['label'] != 'Unknown') DataTable(
                            columns: const [
                              DataColumn(label: Text('Nutrient')),
                              DataColumn(label: Text('Per Serving')),
                              DataColumn(label: Text('Per 100g')),
                            ],
                            dataRowHeight: 25,
                            headingRowHeight: 30,
                            rows: _getRowsFromResponse(_responseBody!),
                          ) else const Text(
                            "No Nutrition Information Found",
                            style: TextStyle(
                                color: Colors.black,
                                fontStyle: FontStyle.italic,
                                fontSize: 20
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              }).toList()
                  : [],
            ),
          )


        ],
      );

  List<DataRow> _getRowsFromResponse(String responseBody) {
    final rows = <DataRow>[];
    final entities = responseBody.split('\n');
    for (final entity in entities) {
      final parts = entity.split(' ');
      final nutrientParts = parts.sublist(0, parts.length - 2);
      final nutrient = nutrientParts.join(' ');
      final amount = parts[parts.length - 2].isEmpty && parts.last.isEmpty ? ' - ' : parts[parts.length - 2];
      final per100g = parts.last.isEmpty && parts[parts.length - 2].isEmpty ? ' - ' : parts.last;
      rows.add(DataRow(cells: [
        DataCell(SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  nutrient,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
        DataCell(SizedBox(
          width: double.infinity,
          child: Text(
            amount,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),
        DataCell(SizedBox(
          width: double.infinity,
          child: Text(
            per100g,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ]));
    }
    return rows;
  }


}
