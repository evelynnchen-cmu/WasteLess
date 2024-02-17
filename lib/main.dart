import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api_keys.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());
const Color WLGreen = Color(0xFF8aab28);

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  XFile? _image;
  Map<String, String> _formData = {
    'item': '',
    'duration': '',
    'environment': '',
    'physicalChanges': '',
    'dietaryConditions': '',
  };

  String selectedFile = '';
  Uint8List? image;
  String _visionApiResponse = '';
  String _geminiApiResponse = '';

  void _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.first.name;
        image = result.files.first.bytes;
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (image == null) return; // Ensure there's an image selected
    String base64Image = base64Encode(image!);
    String googleCloudVisionApiKey = SecretGoogleCloudVisionApiKey;
    String apiURL =
        'https://vision.googleapis.com/v1/images:annotate?key=$googleCloudVisionApiKey';

    var request = {
      "requests": [
        {
          // "image": {"content": base64Image},
          "image": {
            "source": {"imageUri": "../bread.jpg"}
          },
          "features": [
            {
              "type": "LABEL_DETECTION",
              "maxResults": 10
            }, // General labels about the image
            {
              "type": "OBJECT_LOCALIZATION",
              "maxResults": 10
            }, // Detect objects within the image
            {
              "type": "TEXT_DETECTION",
              "maxResults": 5
            }, // Detect and extract text within the image
          ]
        }
      ]
    };

    var response = await http.post(
      Uri.parse(apiURL),
      body: jsonEncode(request),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      setState(() {
        _visionApiResponse = response.body;
      });
    } else {
      print('Failed to analyze image. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> _previewData() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Map<String, dynamic> visionAnalysis = {};
    if (_visionApiResponse.isNotEmpty) {
      try {
        visionAnalysis = jsonDecode(_visionApiResponse);
      } catch (e) {
        print('Error decoding _visionApiResponse: $e');
      }
    }

    Map<String, dynamic> combinedData = {
      'userInput': _formData,
      'visionAnalysis': visionAnalysis,
    };

    print('Combined Data to be Sent:');
    print(jsonEncode(combinedData));
  }

  // Future<void> _submitToGeminiApi() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   _formKey.currentState!.save();

  //   Map<String, dynamic> combinedData = {
  //     'userInput': _formData,
  //     'visionAnalysis': jsonDecode(_visionApiResponse),
  //   };

  //   String geminiApiUrl = 'YOUR_GEMINI_API_ENDPOINT';
  //   var geminiResponse = await http.post(
  //     Uri.parse(geminiApiUrl),
  //     body: jsonEncode(combinedData),
  //     headers: {"Content-Type": "application/json"},
  //   );

  //   if (geminiResponse.statusCode == 200) {
  //     setState(() {
  //       _geminiApiResponse = geminiResponse.body;
  //     });
  //   } else {
  //     print('Failed to send data to Gemini API');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('WasteLess'),
          backgroundColor: WLGreen,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (_image != null) Image.file(File(_image!.path)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _selectFile,
                  child: Text('Upload Image'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'What is the item?',
                            prefixIcon: Icon(Icons.fastfood, color: WLGreen),
                          ),
                          onSaved: (value) => _formData['item'] = value!,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText:
                                'How long has the item been in this state?',
                            prefixIcon:
                                Icon(Icons.hourglass_bottom, color: WLGreen),
                          ),
                          onSaved: (value) => _formData['duration'] = value!,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'What is its environment like?',
                            prefixIcon: Icon(Icons.eco, color: WLGreen),
                          ),
                          onSaved: (value) => _formData['environment'] = value!,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Any noticeable physical changes?',
                            prefixIcon: Icon(Icons.visibility, color: WLGreen),
                          ),
                          onSaved: (value) =>
                              _formData['physicalChanges'] = value!,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Are there any dietary conditions?',
                            prefixIcon:
                                Icon(Icons.local_dining, color: WLGreen),
                          ),
                          onSaved: (value) =>
                              _formData['dietaryConditions'] = value!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _previewData,
                  child: Text('Evaluate My Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WLGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
