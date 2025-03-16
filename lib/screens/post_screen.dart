import 'package:flutter/material.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostPageState();
}

class _PostPageState extends State<PostScreen> {
  String? selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      resizeToAvoidBottomInset: true,
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
              onTap: () => _showTypeDialog(context),
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
                  label: const Text('Link', style: TextStyle(color: Colors.white)),
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
    );
  }

  void _showTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Reporters', style: TextStyle(color: Colors.white)),
                onTap: () => _selectType('Reporters'),
              ),
              ListTile(
                title: const Text('Islamic Knowledge', style: TextStyle(color: Colors.white)),
                onTap: () => _showIslamicOptions(context),
              ),
              ListTile(
                title: const Text('Discussion', style: TextStyle(color: Colors.white)),
                onTap: () => _selectType('Discussion'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIslamicOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Islamic Knowledge', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIslamicOption('assets/quran.png', 'Teaching Quran', 'Teaching Quran'),
                  _buildIslamicOption('assets/hadith.png', 'Hadith', 'Hadith'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIslamicOption('assets/tafsir.png', 'Tafsir', 'Tafsir'),
                  _buildIslamicOption('assets/sunnah.png', 'Sunnah', 'Sunnah'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIslamicOption(String iconPath, String label, String type) {
    return GestureDetector(
      onTap: () => _selectType(type),
      child: Column(
        children: [
          Image.asset(iconPath, width: 50, height: 50),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _selectType(String type) {
    setState(() => selectedType = type);
    Navigator.pop(context);
  }
}
