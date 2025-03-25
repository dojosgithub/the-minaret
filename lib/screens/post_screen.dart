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
                    ListTile(
                      leading: SvgPicture.asset('assets/quran.svg', height: 24, width: 24),
                      title: const Text('Teaching Quran', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Teaching Quran';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: SvgPicture.asset('assets/hadith.svg', height: 24, width: 24),
                      title: const Text('Hadith', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Hadith';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: SvgPicture.asset('assets/tafsir.svg', height: 24, width: 24),
                      title: const Text('Tafsir', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Tafsir';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: SvgPicture.asset('assets/sunnah.svg', height: 24, width: 24),
                      title: const Text('Sunnah', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Sunnah';
                        });
                        Navigator.pop(context);
                      },
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

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 2, // Adjust the index based on the navigation order
        child: WillPopScope(
        onWillPop: _onWillPop,
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.collections, color: Colors.white),
                      label: const Text('Photos / Videos', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D1B45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text('Post', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D1B45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

