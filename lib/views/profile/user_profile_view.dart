import 'package:flutter/material';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/firebase_service.dart';
import '../call/call_screen.dart';

class UserProfileView extends StatelessWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  String _formatLastSeen(DateTime lastSeen, bool isOnline) {
    if (isOnline) return 'Online Now';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Last seen yesterday';
    return 'Last seen ${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      appBar: AppBar(
        title: const Text("Premium Member", style: TextStyle(color: AppTheme.goldPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.goldPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.usersCollection.doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary));
          }
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          
          final fullName = userData?['fullName'] ?? userName;
          final username = userData?['username'] ?? 'member';
          final profilePic = userData?['profilePic'] ?? userAvatar;
          final bio = userData?['bio'] ?? 'English Chat Premium Member';
          final country = userData?['country'] ?? 'United States';
          final gender = userData?['gender'] ?? 'Not Specified';
          final dob = userData?['dateOfBirth'] ?? 'Not Specified';
          final isOnline = userData?['isOnline'] ?? false;
          final lastSeenTimestamp = userData?['lastSeen'] as Timestamp?;
          final lastSeen = lastSeenTimestamp?.toDate() ?? DateTime.now();
          final joinedTimestamp = userData?['dateJoined'] as Timestamp?;
          final joined = joinedTimestamp?.toDate() ?? DateTime.now();

          // Simple emoji flag lookup
          String flag = "🇺🇸";
          if (country.toLowerCase().contains("kingdom") || country.toLowerCase().contains("uk")) flag = "🇬🇧";
          else if (country.toLowerCase().contains("canada")) flag = "🇨🇦";
          else if (country.toLowerCase().contains("australia")) flag = "🇦🇺";
          else if (country.toLowerCase().contains("india")) flag = "🇮🇳";
          else if (country.toLowerCase().contains("germany")) flag = "🇩🇪";
          else if (country.toLowerCase().contains("france")) flag = "🇫🇷";
          else if (country.toLowerCase().contains("japan")) flag = "🇯🇵";
          else if (country.toLowerCase().contains("brazil")) flag = "🇧🇷";
          else if (country.toLowerCase().contains("saudi")) flag = "🇸🇦";
          else if (country.toLowerCase().contains("pakistan")) flag = "🇵🇰";
          else if (country.toLowerCase().contains("bangladesh")) flag = "🇧🇩";
          else if (country.toLowerCase().contains("turkey")) flag = "🇹🇷";
          else if (country.toLowerCase().contains("mexico")) flag = "🇲🇽";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.goldPrimary, AppTheme.goldDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.charcoalDark,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                          child: profilePic.isEmpty ? const Icon(Icons.person, size: 50, color: AppTheme.goldPrimary) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 8,
                        child: Container(
                          height: 18,
                          width: 18,
                          decoration: BoxDecoration(
                            color: isOnline ? AppTheme.statusGreen : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.charcoalDark, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  textAlign: Center,
                ),
                Text(
                  "@$username",
                  style: const TextStyle(fontSize: 13, color: AppTheme.goldPrimary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? AppTheme.statusGreen.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isOnline ? AppTheme.statusGreen.withOpacity(0.3) : Colors.white12),
                  ),
                  child: Text(
                    isOnline ? "ONLINE" : _formatLastSeen(lastSeen, isOnline),
                    style: TextStyle(
                      color: isOnline ? AppTheme.statusGreen : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Bio Card
                _buildProfileDetailCard("Bio Details", bio, Icons.info_outline_rounded),
                const SizedBox(height: 16),
                
                // Row details
                Row(
                  children: [
                    Expanded(child: _buildProfileMiniCard("Gender", gender, Icons.face_rounded)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildProfileMiniCard("Country", "$flag $country", Icons.public_rounded)),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildProfileMiniCard("Date of Birth", dob, Icons.cake_rounded)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildProfileMiniCard("Joined", "${joined.day}/${joined.month}/${joined.year}", Icons.verified_user_rounded)),
                  ],
                ),
                const SizedBox(height: 40),

                // Fast Calls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCallActionButton(
                      context,
                      icon: Icons.phone_rounded,
                      label: "Voice Call",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              callId: userId,
                              targetUserId: userId,
                              targetUserName: fullName,
                              type: "voice",
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    _buildCallActionButton(
                      context,
                      icon: Icons.videocam_rounded,
                      label: "Video Call",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              callId: userId,
                              targetUserId: userId,
                              targetUserName: fullName,
                              type: "video",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileDetailCard(String title, String val, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldPrimary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildProfileMiniCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.charcoalLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldPrimary, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCallActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.goldPrimary.withOpacity(0.1),
              border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
            ),
            child: Icon(icon, color: AppTheme.goldPrimary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
