import 'package:flutter/material';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../chat/private_chat_screen.dart';
import '../chat/group_chat_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';
import '../call/call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = ["Golden Chats", "Premium Rooms", "Elite Friends", "Settings"];

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    final List<Widget> tabs = [
      const ChatsTab(),
      const GroupsTab(),
      const FriendsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CallHistoryScreen()));
            },
            icon: const Icon(Icons.history_rounded, color: AppTheme.goldPrimary),
          )
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.charcoalLight,
        selectedItemColor: AppTheme.goldPrimary,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline_rounded), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildChatTile(
          context,
          chatId: "chat_maria",
          name: "Maria",
          avatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop",
          lastMessage: "how are you maria",
          time: "7:41 PM",
          isOnline: true,
        ),
        _buildChatTile(
          context,
          chatId: "chat_ram",
          name: "Ram ❤️ krishna",
          avatar: "",
          lastMessage: "hi",
          time: "7:30 PM",
          isOnline: false,
        ),
        _buildChatTile(
          context,
          chatId: "chat_hagana",
          name: "hagana",
          avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop",
          lastMessage: "good",
          time: "6:15 PM",
          isOnline: false,
        ),
      ],
    );
  }

  Widget _buildChatTile(
    BuildContext context, {
    required String chatId,
    required String name,
    required String avatar,
    required String lastMessage,
    required String time,
    required bool isOnline,
  }) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrivateChatScreen(
              chatId: chatId,
              friendName: name,
              friendProfilePic: avatar,
            ),
          ),
        );
      },
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.charcoalLight,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person, color: AppTheme.goldPrimary) : null,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: AppTheme.statusGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.charcoalDark, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(lastMessage, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Text(time, style: const TextStyle(color: Colors.white24, fontSize: 10)),
    );
  }
}

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildGroupTile(
          context,
          groupId: "group_designers",
          name: "Premium Design Group",
          avatar: "",
          lastMessage: "Sent a luxurious new color gradient.",
          time: "9:15 AM",
        ),
        _buildGroupTile(
          context,
          groupId: "group_devs",
          name: "Firebase Backend Guild",
          avatar: "",
          lastMessage: "Security rules deployed.",
          time: "Tuesday",
        ),
      ],
    );
  }

  Widget _buildGroupTile(BuildContext context, {required String groupId, required String name, required String avatar, required String lastMessage, required String time}) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: groupId,
              groupName: name,
              groupAvatar: avatar,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: AppTheme.goldPrimary.withOpacity(0.1),
        child: const Icon(Icons.groups_rounded, color: AppTheme.goldPrimary),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(lastMessage, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Text(time, style: const TextStyle(color: Colors.white24, fontSize: 10)),
    );
  }
}
