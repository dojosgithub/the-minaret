import 'package:flutter/material.dart';
import 'home_screen.dart'; // Ensure this is the correct import for your home screen.

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F245A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TextField(
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFFFDCC87)),
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF3D1B45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildExpansionTile('Sort by', ['Date', 'Most Relevant', 'Recent']),
                        _buildExpansionTile('Date Posted', ['Last 24 Hours', 'This Week', 'This Month', '2024']),
                        _buildExpansionTile('Posted By', ['Me', 'Followings', 'Anyone']),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDCC87),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Show Results', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(String title, List<String> options) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(color: Color(0xFFFDCC87))),
      children: options
          .map(
            (option) => Column(
              children: [
                ListTile(
                  title: Text(option, style: const TextStyle(color: Color(0xFFFDCC87))),
                  onTap: () => Navigator.pop(context, option),
                ),
                if (option != options.last) const Divider(color: Colors.grey, thickness: 0.5),
              ],
            ),
          )
          .toList(),
    );
  }
}
