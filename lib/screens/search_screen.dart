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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
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
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF3D1B45),
              isScrollControlled: true,
              builder: (BuildContext context) {
                return DraggableScrollableSheet(
                  expand: false,
                  builder: (context, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3D1B45),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
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
            (option) => ListTile(
              title: Text(option, style: const TextStyle(color: Color(0xFFFDCC87))),
              onTap: () => Navigator.pop(context, option),
            ),
          )
          .toList(),
    );
  }
}
