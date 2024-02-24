import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Evaluate the safety of your food in seconds by following these simple steps:',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text('1. Upload a picture of your food item.'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text('2. Fill in the details about the item.'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text('3. Submit to get the safety evaluation.'),
                  ),
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
  String selectedFile = '';

  void _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      setState(() {
        selectedFile = result.files.single.name;
        image = result.files.single.bytes;
      });
    } else {
      setState(() {
        selectedFile = '';
        image = null;
      });
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
    });
  }

  // Replace Cloud Vision API with Gemini API Call
  Future<void> _sendToGemini() async {
    print("Sending data to Gemini...");
    assert(image != null, 'Image is null');

    if (image == null) return;
    print('A');
    const apiKey = 'AIzaSyBIRTYOW5efd2LBCGP-r8s_4fhLKwkisUo';
    final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
    final prompt = _buildPrompt();
    print('B');

    // Convert image to suitable format for Gemini API
    final imageBytes = image!;
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes), // Assuming JPEG format for simplicity
      ])
    ];

    print('C');

    // Send data to Gemini and handle the response
    try {
      print('calling api');
      final response = await model.generateContent(content);
      print('got response');
      final String text = response.text ?? '';
      if (text != '') {
        _displayGeminiResponse(text);
      } else {
        throw Exception('Failed to get response from Gemini');
      }
    } catch (e) {
      print('Failed to send data to Gemini: $e');
    }
  }

  // Construct the prompt for Gemini based on form data
  String _buildPrompt() {
    String _item = _formData['item'] ?? '';
    String _duration = _formData['duration'] ?? '';
    String _sealed = _formData['sealed'] ?? '';
    String _environment = _formData['environment'] ?? '';
    String _physicalChanges = _formData['physicalChanges'] ?? '';
    String _dietaryConditions = _formData['dietaryConditions'] ?? '';

    return 'Assess the safety of consuming the food item detailed below and in the provided image, and give a confidence score at the VERY BEGINNING of your response, such as "High/Med/Low confidence that it is edible/inedible/expired". Note: Your suggestion is understood as non-professional advice, so do not include that information.\n\n'
          'Food Item: $_item\n'
          'Age: $_duration\n'
          'Storage: $_sealed, $_environment\n'
          'Physical Changes: $_physicalChanges\n'
          'Dietary Conditions: $_dietaryConditions\n\n'
          'Do not make assumptions about the food, especially if it was refrigerated or stored properly or not.\n\n'
          'Focus on providing a clear, concise evaluation. Avoid stating disclaimers about being an LLM or not a health professional. Do give some concise insight on your reasoning, but avoid repeating the same information. Inspect the image closely and provide your thoughts and analysis, paying attention to any red or green flags.\n\n'
          'The purpose of this is not explicitely to determine if the food is good or bad, but to do this in conjunction with preventing food waste. If there is food that is still technically good to eat, we do not want to false flag it and have it thrown out.\n\n'
          'Despite this, however, be conscious of health concerns. Be wary of bacterial growth IF applicable from the picture and the provided context (such as time left out). If not applicable, do not address it.';
  }

  // Display Gemini response in the UI
  void _displayGeminiResponse(String responseText) {
    print('Displaying Gemini response...');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataDisplayScreen(responseText: responseText),
      ),
    );
    // _resetFormAndData(); // Commented out for repeat testing purposes
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
              selectedFile.isEmpty ? 'No image uploaded' : 'Uploaded: $selectedFile',
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
                        prefixIcon: Icon(Icons.hourglass_bottom, color: WLGreen),
                      ),
                      onSaved: (value) => _formData['duration'] = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Was the item sealed or unsealed?',
                        prefixIcon: Icon(Icons.storage, color: WLGreen),
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
                      onSaved: (value) => _formData['dietaryConditions'] = value!,
                    ),
                  ],
                ),
              ),
            ),
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _formKey.currentState!.save();
                    _sendToGemini();
                  },
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
  final String responseText;

  const DataDisplayScreen({Key? key, required this.responseText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Directly use the responseText in your UI
    return Scaffold(
      appBar: AppBar(
        title: Text('WasteLess'),
        backgroundColor: WLGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Your Item Evaluation:",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: WLGreen),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                responseText, // Display the response text directly
                style: TextStyle(fontSize: 16),
              ),
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
