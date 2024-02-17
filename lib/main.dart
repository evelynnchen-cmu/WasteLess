import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api_keys.dart';

void main() => runApp(MyApp());

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
  String _visionApiResponse = '';
  String _geminiApiResponse = '';

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
    if (_image != null) {
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    final bytes = await _image!.readAsBytes();
    String base64Image = base64Encode(bytes);
    String googleCloudVisionApiKey = SecretGoogleCloudVisionApiKey;
    String apiURL =
        'https://vision.googleapis.com/v1/images:annotate?key=$googleCloudVisionApiKey';
    var response = await http.post(
      Uri.parse(apiURL),
      body: jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION"}
            ],
          }
        ]
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      setState(() {
        _visionApiResponse = response.body;
      });
    } else {
      print('Failed to analyze image');
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('WasteLess')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (_image != null) Image.file(File(_image!.path)),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Upload Image'),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'What is the item?',
                        prefixIcon: Icon(Icons.fastfood, color: Color( 0xFF8aab28)),
                      ),
                      onSaved: (value) => _formData['item'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'How long has the item been in this state?',
                        prefixIcon: Icon(Icons.hourglass_bottom, color: Color( 0xFF8aab28)),
                      ),
                      onSaved: (value) => _formData['duration'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText:
                            'What is its environment like?',
                        prefixIcon: Icon(Icons.eco, color: Color( 0xFF8aab28)),
                      ),
                      onSaved: (value) => _formData['environment'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Any noticeable physical changes?',
                        prefixIcon: Icon(Icons.visibility, color: Color( 0xFF8aab28)),
                      ),
                      onSaved: (value) => _formData['physicalChanges'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText:
                            'Are there any dietary conditions?',
                        prefixIcon: Icon(Icons.local_dining, color: Color( 0xFF8aab28)),
                      ),
                      onSaved: (value) => _formData['dietaryConditions'] = value!,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _previewData,
                child: Text('Evaluate My Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                      0xFF8aab28), 
                  foregroundColor: Colors.white, 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
