import 'package:flutter/material.dart';

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
          icon: const Icon(Icons.arrow_back, color: Colors.yellow),
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
            icon: const Icon(Icons.sort, color: Colors.yellow),
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
                          ExpansionTile(
                            title: const Text('Sort by', style: TextStyle(color: Colors.yellow)),
                            children: [
                              ListTile(
                                title: const Text('Date', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Date'),
                              ),
                              ListTile(
                                title: const Text('Most Relevant', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Most Relevant'),
                              ),
                              ListTile(
                                title: const Text('Recent', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Recent'),
                              ),
                            ],
                          ),
                          ExpansionTile(
                            title: const Text('Date Posted', style: TextStyle(color: Colors.yellow)),
                            children: [
                              ListTile(
                                title: const Text('Last 24 Hours', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Last 24 Hours'),
                              ),
                              ListTile(
                                title: const Text('This Week', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'This Week'),
                              ),
                              ListTile(
                                title: const Text('This Month', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'This Month'),
                              ),
                              ListTile(
                                title: const Text('2024', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, '2024'),
                              ),
                            ],
                          ),
                          ExpansionTile(
                            title: const Text('Posted By', style: TextStyle(color: Colors.yellow)),
                            children: [
                              ListTile(
                                title: const Text('Me', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Me'),
                              ),
                              ListTile(
                                title: const Text('Followings', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Followings'),
                              ),
                              ListTile(
                                title: const Text('Anyone', style: TextStyle(color: Colors.yellow)),
                                onTap: () => Navigator.pop(context, 'Anyone'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}