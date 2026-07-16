import 'package:flutter/material';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/friend_controller.dart';
import '../../models/user_model.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FriendController>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Elegant Gold Search
          TextField(
            controller: _searchController,
            onChanged: (val) async {
              final list = await controller.searchUsers(val);
              setState(() => _searchResults = list);
            },
            decoration: InputDecoration(
              hintText: 'Search handle on English chat...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldPrimary),
              filled: true,
              fillColor: AppTheme.charcoalLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? const Center(child: Text("No elite users found."))
                : ListView.builder(
                    itemCount: _searchResults.isEmpty ? 2 : _searchResults.length,
                    itemBuilder: (context, index) {
                      if (_searchResults.isEmpty) {
                        // Static VIP users placeholders when empty search
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: AppTheme.goldPrimary, child: Icon(Icons.star, color: AppTheme.charcoalDark)),
                          title: Text(index == 0 ? "Sarah Jenkins" : "Sophia Martinez"),
                          subtitle: Text(index == 0 ? "@sarah_vip" : "@sophia_m"),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add_rounded, color: AppTheme.goldPrimary),
                            onPressed: () {},
                          ),
                        );
                      }
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(user.profilePic)),
                        title: Text(user.fullName),
                        subtitle: Text("@${user.username}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary),
                          onPressed: () {},
                          child: const Text("ADD", style: TextStyle(color: AppTheme.charcoalDark, fontSize: 10)),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
