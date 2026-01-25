import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool loading = false;

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => loading = true);

    final url =
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5";
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'trippo_mobile_app/1.0 (subinakhaderbs@gmail.com)'
    });
    // if (!mounted) return; // ⛔ prevent setState after dispose

    if (response.statusCode == 200) {
      results = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      results = [];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: darkTheme ? Colors.black : Colors.white,
            ),
          ),
          title: Text(
            "Search location",
            style: TextStyle(
              color: darkTheme ? Colors.black : Colors.white,
            ),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.adjust_sharp,
                      color: darkTheme ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: searchLocation,
                        decoration: InputDecoration(
                          hintText: "Search location here...",
                          fillColor:
                          darkTheme ? Colors.black : Colors.white54,
                          filled: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            left: 11,
                            top: 8,
                            bottom: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (loading) const LinearProgressIndicator(),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text("No results"))
                  : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final place = results[index];
                  return ListTile(
                    title: Text(place['display_name']),
                    onTap: () => Navigator.pop(context, place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
