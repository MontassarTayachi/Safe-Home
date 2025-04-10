import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? imageUrl;
  String? time;

  @override
  void initState() {
    super.initState();
    fetchLastImage();
  }

  Future<void> fetchLastImage() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.10.0.200:3000/images/last'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          imageUrl = data['imageUrl'];
          time = data['time'];
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeHome'),
      ),
      body: Center(
        child: imageUrl == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Last Detected Image:',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Image.network(imageUrl!),
                  const SizedBox(height: 10),
                  Text(
                    'Detected at: $time',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchLastImage,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
      ),
    );
  }
}
