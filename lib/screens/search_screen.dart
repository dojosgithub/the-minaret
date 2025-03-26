import 'package:flutter/material.dart';
import '../widgets/screen_wrapper.dart';
import 'home_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4F245A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              height: 50, // Fix height to prevent cutting
              child: TextField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20), // Increased curvature
                    borderSide: BorderSide.none,
                  ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExpansionTile(context, 'Sort by', ['Date', 'Most Relevant', 'Recent']),
                          _buildExpansionTile(context, 'Date Posted', ['Last 24 Hours', 'This Week', 'This Month', '2024']),
                          _buildExpansionTile(context, 'Posted By', ['Me', 'Followings', 'Anyone']),
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recently Searched",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildRecentlySearchedOption("Today's Breaking News"),
              _buildRecentlySearchedOption("Teaching of the Quran"),
              _buildRecentlySearchedOption("Islamic Knowledge"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlySearchedOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFFFDCC87)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              // Handle removal of the option
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(BuildContext context, String title, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0), // Indentation for suboptions
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(color: Color(0xFFFDCC87))),
        children: options
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(left: 20.0), // Further indentation for suboptions
                child: ListTile(
                  title: Text(option, style: const TextStyle(color: Color(0xFFFDCC87))),
                  onTap: () {
                    // Do nothing here to ensure popup doesn't close
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}