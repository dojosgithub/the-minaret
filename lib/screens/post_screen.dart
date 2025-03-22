import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                    onPressed: () {
                      debugPrint("add photos / videos");
                    },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.12; // 12% of screen width
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Islamic Knowledge', style: TextStyle(color: Colors.white)),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildIslamicOption('assets/quran.svg', 'Teaching Quran', 'Teaching Quran', iconSize)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildIslamicOption('assets/hadith.svg', 'Hadith', 'Hadith', iconSize)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildIslamicOption('assets/tafsir.svg', 'Tafsir', 'Tafsir', iconSize)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildIslamicOption('assets/sunnah.svg', 'Sunnah', 'Sunnah', iconSize)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIslamicOption(String iconPath, String label, String type, double size) {
    return GestureDetector(
      onTap: () {
        _selectType(type);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: size,
            height: size,
            color: const Color(0xFFFDCC87),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.2, // 20% of icon size
            ),
          ),
        ],
      ),
    );
  }

  void _selectType(String type) {
    setState(() {
      selectedType = type;
      _hasChanges = true;
    });
    Navigator.pop(context);
  }
}
