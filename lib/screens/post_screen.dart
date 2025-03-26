import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/screen_wrapper.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostPageState();
}

class _PostPageState extends State<PostScreen> {
  String? selectedType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onChangesMade);
    _bodyController.addListener(_onChangesMade);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onChangesMade() {
    if (!_hasChanges && (_titleController.text.isNotEmpty || _bodyController.text.isNotEmpty || selectedType != null)) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D1B45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Discard Post?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to go back and discard the post?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFFDCC87),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showOptionsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedMainOption;
        String? selectedSubOption;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF3D1B45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedMainOption == null) ...[
                    ListTile(
                      title: const Text('Reporters', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Reporters';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text('Islamic Knowledge', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() => selectedMainOption = 'Islamic Knowledge');
                      },
                    ),
                    ListTile(
                      title: const Text('Discussion', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Discussion';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ] else if (selectedMainOption == 'Islamic Knowledge') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSubOption(
                          context,
                          'Teaching Quran',
                          'assets/quran.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                          },
                        ),
                        const SizedBox(width: 10), // Add space between suboptions
                        _buildSubOption(
                          context,
                          'Hadith',
                          'assets/hadith.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                          },
                        ),
                        const SizedBox(width: 10), // Add space between suboptions
                        _buildSubOption(
                          context,
                          'Tafsir',
                          'assets/tafsir.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                          },
                        ),
                        const SizedBox(width: 10), // Add space between suboptions
                        _buildSubOption(
                          context,
                          'Sunnah',
                          'assets/sunnah.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubOption(BuildContext context, String label, String assetPath, String? selected, Function(String) onTap) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFDCC87) : const Color(0xFF3D1B45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              assetPath,
              height: 40,
              width: 40,
              colorFilter: ColorFilter.mode( // Replaced deprecated color parameter
                isSelected ? Colors.black : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(color: isSelected ? Colors.black : const Color(0xFFFDCC87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 2, // Adjust the index based on the navigation order
      child: PopScope( // Replaced deprecated WillPopScope
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final shouldPop = await _onWillPop();
            if (shouldPop) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF4F245A),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFDCC87),
                      ),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage('assets/profile_picture.png'),
                        radius: 25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showOptionsPopup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1B45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedType ?? 'Type', style: const TextStyle(color: Color(0xFFFDCC87))),
                        const Icon(Icons.add, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D1B45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        maxLines: 1,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Title of Post',
                          hintStyle: TextStyle(color: Color(0xFFFDCC87)),
                        ),
                      ),
                      const Divider(color: Color(0xFFFDCC87)),
                      TextField(
                        controller: _bodyController,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Body Text',
                          hintStyle: TextStyle(color: Color(0xFFFDCC87)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D1B45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50), // Full width
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // Float text to the left
                    children: const [
                      Icon(Icons.collections, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Photos / Videos', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D1B45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50), // Full width
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // Float text to the left
                    children: const [
                      Icon(Icons.send, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Link', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Handle post action
            },
            backgroundColor: const Color(0xFFFDCC87),
            child: const Icon(Icons.post_add, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
