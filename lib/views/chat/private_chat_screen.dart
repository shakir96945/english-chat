import 'dart:io';
import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/message_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/google_translate_service.dart';
import '../call/call_screen.dart';
import '../profile/user_profile_view.dart';

class PrivateChatScreen extends StatefulWidget {
  final String chatId;
  final String friendName;
  final String friendProfilePic;

  const PrivateChatScreen({
    super.key,
    required this.chatId,
    required this.friendName,
    required this.friendProfilePic,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  MessageModel? _replyMessage;
  MessageModel? _editingMessage;
  bool _isTyping = false;
  bool _isUploading = false;
  String _uploadStatus = "";

  bool _isNotificationsMuted = false;
  bool _messageNotificationsOn = true;
  bool _callNotificationsOn = true;

  final List<String> _quickReactions = ["❤️", "👍", "🔥", "😂", "😮", "🙏"];

  @override
  void initState() {
    super.initState();
    _msgController.addListener(_onTextChanged);
    
    // Mark incoming messages as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatController = Provider.of<ChatController>(context, listen: false);
      chatController.markMessagesAsRead(widget.chatId, widget.chatId);
    });
  }

  @override
  void dispose() {
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentlyTyping = _msgController.text.isNotEmpty;
    if (currentlyTyping != _isTyping) {
      setState(() {
        _isTyping = currentlyTyping;
      });
      Provider.of<ChatController>(context, listen: false)
          .updateTypingStatus(widget.chatId, _isTyping);
    }
  }

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

  Future<void> _pickAndUploadAttachment(String mediaType) async {
    try {
      File? file;
      String type = 'text';
      String fileName = '';

      final picker = ImagePicker();

      if (mediaType == 'camera_img') {
        final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
        if (picked != null) {
          file = File(picked.path);
          type = 'image';
          fileName = picked.name;
        }
      } else if (mediaType == 'gallery_img') {
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
        if (picked != null) {
          file = File(picked.path);
          type = 'image';
          fileName = picked.name;
        }
      } else if (mediaType == 'video') {
        final picked = await picker.pickVideo(source: ImageSource.gallery);
        if (picked != null) {
          file = File(picked.path);
          type = 'video';
          fileName = picked.name;
        }
      } else if (mediaType == 'document') {
        final picked = await FilePicker.platform.pickFiles(type: FileType.any);
        if (picked != null && picked.files.single.path != null) {
          file = File(picked.files.single.path!);
          type = 'file';
          fileName = picked.files.single.name;
        }
      }

      if (file != null) {
        setState(() {
          _isUploading = true;
          _uploadStatus = "Uploading custom media...";
        });

        final chatController = Provider.of<ChatController>(context, listen: false);
        final mediaUrl = await chatController.uploadSharedMedia(file, widget.chatId, type);

        await chatController.sendChatMessage(
          chatId: widget.chatId,
          text: type == 'image' ? "Sent an image" : type == 'video' ? "Sent a video" : "Shared document: $fileName",
          type: type,
          mediaUrl: mediaUrl,
          fileName: fileName,
        );

        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Premium attachment delivered!")),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: $e")),
      );
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.charcoalLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Send Premium Media", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(Icons.camera_alt_rounded, "Camera", Colors.amber, () {
                      Navigator.pop(context);
                      _pickAndUploadAttachment('camera_img');
                    }),
                    _buildAttachmentOption(Icons.photo_library_rounded, "Gallery", Colors.purple, () {
                      Navigator.pop(context);
                      _pickAndUploadAttachment('gallery_img');
                    }),
                    _buildAttachmentOption(Icons.videocam_rounded, "Video", Colors.red, () {
                      Navigator.pop(context);
                      _pickAndUploadAttachment('video');
                    }),
                    _buildAttachmentOption(Icons.insert_drive_file_rounded, "Document", Colors.blue, () {
                      Navigator.pop(context);
                      _pickAndUploadAttachment('document');
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoalLight,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileView(
                  userId: widget.chatId,
                  userName: widget.friendName,
                  userAvatar: widget.friendProfilePic,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.charcoalDark,
                backgroundImage: widget.friendProfilePic.isNotEmpty ? NetworkImage(widget.friendProfilePic) : null,
                child: widget.friendProfilePic.isEmpty ? const Icon(Icons.person, color: AppTheme.goldPrimary) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.friendName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    
                    // Real-time Presence, Typing and Last-seen Info
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseService.usersCollection.doc(widget.chatId).snapshots(),
                      builder: (context, userSnap) {
                        final userData = userSnap.data?.data() as Map<String, dynamic>?;
                        final isOnline = userData?['isOnline'] ?? false;
                        final lastSeenTimestamp = userData?['lastSeen'] as Timestamp?;
                        final lastSeen = lastSeenTimestamp?.toDate() ?? DateTime.now();

                        return StreamBuilder<DocumentSnapshot>(
                          stream: chatController.getChatRoomStream(widget.chatId),
                          builder: (context, chatSnap) {
                            final chatData = chatSnap.data?.data() as Map<String, dynamic>?;
                            final typingMap = chatData?['typingStatus'] as Map<String, dynamic>?;
                            final peerIsTyping = typingMap?[widget.chatId] ?? false;

                            if (peerIsTyping) {
                              return const Text(
                                'typing...',
                                style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                              );
                            }

                            return Text(
                              isOnline ? 'Online' : _formatLastSeen(lastSeen, isOnline),
                              style: TextStyle(
                                color: isOnline ? AppTheme.statusGreen : Colors.white38,
                                fontSize: 10,
                                fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    callId: widget.chatId,
                    targetUserId: widget.chatId,
                    targetUserName: widget.friendName,
                    type: "voice",
                  ),
                ),
              );
            },
            icon: const Icon(Icons.phone_rounded, color: AppTheme.goldPrimary),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    callId: widget.chatId,
                    targetUserId: widget.chatId,
                    targetUserName: widget.friendName,
                    type: "video",
                  ),
                ),
              );
            },
            icon: const Icon(Icons.videocam_rounded, color: AppTheme.goldPrimary),
          ),
          
          // Redesigned Three Dot Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.goldPrimary),
            backgroundColor: AppTheme.charcoalLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) => _handleMenuAction(val, authController),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: Colors.redAccent.withOpacity(0.8), size: 18),
                    const SizedBox(width: 10),
                    const Text("Block Spammer", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Colors.amber.withOpacity(0.8), size: 18),
                    const SizedBox(width: 10),
                    const Text("Report User", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded, color: AppTheme.goldPrimary.withOpacity(0.8), size: 18),
                    const SizedBox(width: 10),
                    const Text("Clear Chat", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_chat',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    const Text("Delete Entire Chat", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(_isNotificationsMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: AppTheme.goldPrimary, size: 18),
                    const SizedBox(width: 10),
                    Text(_isNotificationsMuted ? "Unmute Alerts" : "Mute Alerts", style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_msg',
                child: Row(
                  children: [
                    Icon(_messageNotificationsOn ? Icons.message_rounded : Icons.speaker_notes_off_rounded, color: AppTheme.goldPrimary, size: 18),
                    const SizedBox(width: 10),
                    Text("Messages: ${_messageNotificationsOn ? 'ON' : 'OFF'}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_call',
                child: Row(
                  children: [
                    Icon(_callNotificationsOn ? Icons.call_rounded : Icons.phone_locked_rounded, color: AppTheme.goldPrimary, size: 18),
                    const SizedBox(width: 10),
                    Text("Calls: ${_callNotificationsOn ? 'ON' : 'OFF'}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.goldPrimary.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldPrimary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(_uploadStatus, style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatController.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Say hello to widget.friendName with a premium message!", style: TextStyle(color: Colors.white24, fontSize: 12)));
                }
                final messages = snapshot.data!;
                
                // Keep marking as read if the peer sent new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  chatController.markMessagesAsRead(widget.chatId, widget.chatId);
                });

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == authController.currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          _showMessageActions(context, chatController, authController, msg);
                        },
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.goldPrimary : AppTheme.charcoalLight,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                ),
                                border: Border.all(color: isMe ? AppTheme.goldDark.withOpacity(0.4) : AppTheme.goldPrimary.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Reply context
                                  if (msg.replyToText.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(8),
                                        border: const Border(left: BorderSide(color: AppTheme.goldPrimary, width: 3)),
                                      ),
                                      child: Text(
                                        msg.replyToText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 10, color: isMe ? AppTheme.charcoalDark.withOpacity(0.7) : Colors.white60),
                                      ),
                                    ),

                                  // Message content by type
                                  _buildMessageBody(msg, isMe),

                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(color: isMe ? AppTheme.charcoalDark.withOpacity(0.5) : Colors.white38, fontSize: 9),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                          size: 11,
                                          color: msg.isRead ? AppTheme.charcoalDark : AppTheme.charcoalDark.withOpacity(0.5),
                                        ),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                            
                            // Render reactions badge
                            if (msg.reactions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 6),
                                child: Wrap(
                                  spacing: 4,
                                  children: msg.reactions.entries.map((entry) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.charcoalLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3), width: 0.5),
                                      ),
                                      child: Text(entry.value, style: const TextStyle(fontSize: 10)),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_replyMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.charcoalLight,
              border: const Border(top: BorderSide(color: AppTheme.goldPrimary, width: 0.5)),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: AppTheme.goldPrimary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Replying to message", style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(_replyMessage!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => setState(() => _replyMessage = null), icon: const Icon(Icons.close_rounded, size: 18)),
                ],
              ),
            ),

          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.charcoalLight,
              border: const Border(top: BorderSide(color: Colors.blueAccent, width: 0.5)),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Editing selected message", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(_editingMessage!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => setState(() => _editingMessage = null), icon: const Icon(Icons.close_rounded, size: 18)),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppTheme.charcoalLight,
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAttachmentSheet,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.goldPrimary, size: 24),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _editingMessage != null ? "Update message..." : "Type a golden message...",
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppTheme.charcoalDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: AppTheme.goldPrimary,
                  radius: 20,
                  child: IconButton(
                    onPressed: () async {
                      if (_msgController.text.trim().isEmpty) return;
                      final text = _msgController.text;
                      _msgController.clear();

                      if (_editingMessage != null) {
                        final editId = _editingMessage!.id;
                        setState(() => _editingMessage = null);
                        await chatController.editChatMessage(
                          chatId: widget.chatId,
                          messageId: editId,
                          newText: text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium message updated!")));
                      } else {
                        final replyId = _replyMessage?.id ?? '';
                        final replyText = _replyMessage?.text ?? '';
                        setState(() => _replyMessage = null);

                        await chatController.sendChatMessage(
                          chatId: widget.chatId,
                          text: text,
                          replyToId: replyId,
                          replyToText: replyText,
                        );
                      }
                    },
                    icon: Icon(_editingMessage != null ? Icons.check_rounded : Icons.send_rounded, color: AppTheme.charcoalDark, size: 18),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBody(MessageModel msg, bool isMe) {
    if (msg.type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              msg.mediaUrl,
              height: 180,
              width: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                width: 180,
                color: Colors.black26,
                child: const Icon(Icons.broken_image_rounded, color: AppTheme.goldPrimary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(msg.text, style: TextStyle(color: isMe ? AppTheme.charcoalDark : Colors.white, fontSize: 13)),
        ],
      );
    } else if (msg.type == 'video') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.movie_rounded, color: Colors.white24, size: 40),
                CircleAvatar(
                  backgroundColor: AppTheme.goldPrimary.withOpacity(0.85),
                  radius: 22,
                  child: const Icon(Icons.play_arrow_rounded, color: AppTheme.charcoalDark, size: 24),
                )
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(msg.text, style: TextStyle(color: isMe ? AppTheme.charcoalDark : Colors.white, fontSize: 13)),
        ],
      );
    } else if (msg.type == 'file') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: AppTheme.goldPrimary, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.fileName.isNotEmpty ? msg.fileName : "premium_document.pdf",
                    style: TextStyle(color: isMe ? AppTheme.charcoalDark : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text("Premium Document File", style: TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
            )
          ],
        ),
      );
    }

    return Text(
      msg.text,
      style: TextStyle(color: isMe ? AppTheme.charcoalDark : Colors.white, fontSize: 13.5, height: 1.3),
    );
  }

  void _showMessageActions(BuildContext context, ChatController controller, AuthController auth, MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.charcoalLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            // Quick reaction bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              border: const Border(bottom: BorderSide(color: Colors.white10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickReactions.map((emoji) {
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await controller.addMessageReaction(
                        chatId: widget.chatId,
                        messageId: msg.id,
                        userId: auth.currentUser?.uid ?? 'unknown',
                        emoji: emoji,
                      );
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  );
                }).toList(),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppTheme.goldPrimary),
              title: const Text("Reply"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyMessage = msg);
              },
            ),
            if (msg.senderId == auth.currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.goldPrimary),
                title: const Text("Edit Message"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _editingMessage = msg);
                  _msgController.text = msg.text;
                },
              ),
            ListTile(
              leading: const Icon(Icons.g_translate_rounded, color: AppTheme.goldPrimary),
              title: const Text("Translate to Spanish"),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Translating message...")),
                );
                final translated = await GoogleTranslateService.translateText(
                  text: msg.text,
                  targetLanguageCode: 'es',
                );
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppTheme.charcoalLight,
                      title: const Text("Golden Translation", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
                      content: Text(translated, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK", style: TextStyle(color: AppTheme.goldPrimary)),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward_rounded, color: AppTheme.goldPrimary),
              title: const Text("Forward Message"),
              onTap: () {
                Navigator.pop(context);
                _showForwardDialog(controller, msg);
              },
            ),
            if (msg.senderId == auth.currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text("Delete for Everyone"),
                onTap: () async {
                  Navigator.pop(context);
                  await controller.deleteMessageForEveryone(widget.chatId, msg.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message deleted.")));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showForwardDialog(ChatController controller, MessageModel msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoalLight,
        title: const Text("Forward to Partner", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: AppTheme.goldPrimary)),
              title: Text(widget.friendName),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary),
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.sendChatMessage(
                    chatId: widget.chatId,
                    text: msg.text,
                    type: msg.type,
                    mediaUrl: msg.mediaUrl,
                    fileName: msg.fileName,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium message forwarded!")));
                },
                child: const Text("Send", style: TextStyle(color: AppTheme.charcoalDark, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action, AuthController auth) async {
    if (action == 'block') {
      await auth.blockUser(widget.chatId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Blocked ${widget.friendName} successfully.")),
      );
    } else if (action == 'report') {
      _showReportReasonDialog();
    } else if (action == 'clear') {
      _showConfirmClearChat();
    } else if (action == 'delete_chat') {
      _showConfirmDeleteChat();
    } else if (action == 'mute') {
      setState(() {
        _isNotificationsMuted = !_isNotificationsMuted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isNotificationsMuted ? "Notifications muted for this chat." : "Notifications unmuted.")),
      );
    } else if (action == 'toggle_msg') {
      setState(() {
        _messageNotificationsOn = !_messageNotificationsOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message alerts: ${_messageNotificationsOn ? 'ON' : 'OFF'}")),
      );
    } else if (action == 'toggle_call') {
      setState(() {
        _callNotificationsOn = !_callNotificationsOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Call notifications: ${_callNotificationsOn ? 'ON' : 'OFF'}")),
      );
    }
  }

  void _showReportReasonDialog() {
    final reasons = ["Spam Profile", "Harassment or Abuse", "Hate Speech", "Fake Account"];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoalLight,
        title: const Text("Report User", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.map((reason) => ListTile(
            title: Text(reason, style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () async {
              Navigator.pop(context);
              
              // Push to mock / reports collections
              await FirebaseService.firestore.collection('reports').add({
                'reportedUserId': widget.chatId,
                'reporterUserId': Provider.of<AuthController>(context, listen: false).currentUser?.uid,
                'reason': reason,
                'timestamp': FieldValue.serverTimestamp(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report submitted. Premium security team will review.")),
              );
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showConfirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoalLight,
        title: const Text("Clear Chat History", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to permanently clear all messages?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final msgs = await FirebaseService.chatsCollection.doc(widget.chatId).collection('messages').get();
              final batch = FirebaseService.firestore.batch();
              for (var doc in msgs.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat history cleared!")));
            },
            child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoalLight,
        title: const Text("Delete Entire Chat", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("This deletes the entire chat channel and conversation metadata. Continue?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseService.chatsCollection.doc(widget.chatId).delete();
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat channel deleted!")));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
