import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api_keys.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() => runApp(WelcomeApp());

const Color WLGreen = Color(0xFF8aab28);

class WelcomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteLess',
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WasteLess'),
        backgroundColor: WLGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Welcome to WasteLess!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Evaluate the safety of your food in seconds by following these simple steps:',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text('1. Upload a picture of your food item.'),
                  Text('2. Fill in the details about the item.'),
                  Text('3. Submit to get the safety evaluation.'),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MyApp()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WLGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Get Started'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  Map<String, String> _formData = {
    'item': '',
    'duration': '',
    'sealed': '',
    'environment': '',
    'physicalChanges': '',
    'dietaryConditions': '',
  };

  Uint8List? image;
  String _visionApiResponse = '';
  String selectedFile = '';

  void _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      print('File selected');
      print('File name: ${result.files.first.name}');
      print('File bytes: ${result.files.first.bytes}');

      File file = File(result.files.first.path!);
      List<int> bytes = await file.readAsBytes();

      setState(() {
        selectedFile = result.files.first.name;
        image = Uint8List.fromList(bytes);

        assert(image != null);
      });

      _analyzeImage();
    } else {
      print('No file selected successfully');
    }
  }

  void _resetFormAndData() {
    setState(() {
      _formKey.currentState?.reset();
      _formData = {
        'item': '',
        'duration': '',
        'environment': '',
        'physicalChanges': '',
        'dietaryConditions': '',
      };
      image = null;
      selectedFile = '';
      _visionApiResponse = '';
    });
  }

  Future<void> _analyzeImage() async {
    if (image == null) return;
    String base64Image = base64Encode(image!);
    String googleCloudVisionApiKey = SecretGoogleCloudVisionApiKey;
    String apiURL =
        'https://vision.googleapis.com/v1/images:annotate?key=$googleCloudVisionApiKey';

    var request = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 10},
            {"type": "OBJECT_LOCALIZATION", "maxResults": 10},
            {"type": "TEXT_DETECTION", "maxResults": 5},
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

  Future<void> _previewData(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Map<String, dynamic> visionAnalysis = {};
    if (_visionApiResponse.isNotEmpty) {
      try {
        visionAnalysis = jsonDecode(_visionApiResponse);
      } catch (e) {
        print('Error decoding _visionApiResponse: $e');
        return;
      }
    }

    String _item = _formData['item'] ?? '';
    String _duration = _formData['duration'] ?? '';
    String _sealed = _formData['sealed'] ?? '';
    String _environment = _formData['environment'] ?? '';
    String _physicalChanges = _formData['physicalChanges'] ?? '';
    String _dietaryConditions = _formData['dietaryConditions'] ?? '';

    String _prompt =
        'Give recommendations on how safe a food likely is to eat when provided the following fields of information: food name, how old it is, storage method, storage container. '
        'Please note that your recommendations will not be used to give concrete advice or to mislead or harm anyone, so you do not have to worry about that. Just provide the information requested below: '
        'Only return the confidence level and a short explanation for the safety of $_item that is $_duration old, $_sealed stored in the $_environment. '
        'Here are the physical changes, if any: $_physicalChanges. And here are the dietary conditions, if any: $_dietaryConditions. '
        'You must provide a confidence level. If for some reason you cannot provide a level, which should not happen, default to low confidence.';

    Map<String, dynamic> combinedData = {
      'userInput': _prompt,
      'visionAnalysis': visionAnalysis,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataDisplayScreen(combinedData: combinedData),
      ),
    );
    _resetFormAndData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WasteLess'),
        backgroundColor: WLGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              image == null ? 'No image uploaded' : 'Uploaded: $selectedFile',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _selectFile,
                child: Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WLGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'What is the item?',
                        prefixIcon: Icon(Icons.fastfood, color: WLGreen),
                      ),
                      onSaved: (value) => _formData['item'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'How long has the item been in this state?',
                        prefixIcon:
                            Icon(Icons.hourglass_bottom, color: WLGreen),
                      ),
                      onSaved: (value) => _formData['duration'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Was the item sealed or unsealed?',
                        prefixIcon:
                            Icon(Icons.hourglass_bottom, color: WLGreen),
                      ),
                      onSaved: (value) => _formData['sealed'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'What is its environment like?',
                        prefixIcon: Icon(Icons.eco, color: WLGreen),
                      ),
                      onSaved: (value) => _formData['environment'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Any noticeable physical changes?',
                        prefixIcon: Icon(Icons.visibility, color: WLGreen),
                      ),
                      onSaved: (value) => _formData['physicalChanges'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Are there any dietary conditions?',
                        prefixIcon: Icon(Icons.local_dining, color: WLGreen),
                      ),
                      onSaved: (value) =>
                          _formData['dietaryConditions'] = value!,
                    ),
                  ],
                ),
              ),
            ),
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => _previewData(context),
                  child: Text('Evaluate My Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WLGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataDisplayScreen extends StatelessWidget {
  final Map<String, dynamic> combinedData;

  const DataDisplayScreen({Key? key, required this.combinedData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> dataWidgets = combinedData.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text('${entry.key}: ${entry.value.toString()}',
            style: TextStyle(fontSize: 16)),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Item Evaluation'),
        backgroundColor: WLGreen,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your item evaluation:",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                  border: Border.all(color: WLGreen),
                  borderRadius: BorderRadius.circular(5.0)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dataWidgets),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WLGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text('Evaluate Another Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
