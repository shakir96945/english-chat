import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/google_translate_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/message_model.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupAvatar;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupAvatar,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  MessageModel? _replyMessage;
  MessageModel? _editingMessage;
  bool _isUploading = false;

  final List<String> _quickReactions = ["❤️", "👍", "🔥", "😂", "😮", "🙏"];

  @override
  void initState() {
    super.initState();
    _updateTypingStatus(false);
    _msgController.addListener(() {
      _updateTypingStatus(_msgController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateTypingStatus(bool isTyping) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    FirebaseService.firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('typing')
        .doc(uid)
        .set({
      'isTyping': isTyping,
      'fullName': auth.userProfile?.fullName ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendGroupMessage({
    required String text,
    String type = 'text',
    String mediaUrl = '',
    String fileName = '',
  }) async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseService.firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .doc();

    final msg = MessageModel(
      id: docRef.id,
      senderId: uid,
      senderName: auth.userProfile?.fullName ?? 'Elite Member',
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      replyToId: _replyMessage?.id ?? '',
      replyToText: _replyMessage?.text ?? '',
      reactions: {},
    );

    setState(() {
      _replyMessage = null;
    });

    await docRef.set(msg.toMap());
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() => _isUploading = true);
        final file = File(picked.path);
        final url = await FirebaseService.uploadAttachment(
          file: file,
          folder: 'group_chats/${widget.groupId}/images',
        );
        await _sendGroupMessage(text: "Shared an image", type: 'image', mediaUrl: url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: ${e}")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isUploading = true);
        final file = File(picked.path);
        final url = await FirebaseService.uploadAttachment(
          file: file,
          folder: 'group_chats/${widget.groupId}/videos',
        );
        await _sendGroupMessage(text: "Shared a video", type: 'video', mediaUrl: url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: ${e}")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        final file = File(result.files.single.path!);
        final name = result.files.single.name;
        final url = await FirebaseService.uploadAttachment(
          file: file,
          folder: 'group_chats/${widget.groupId}/documents',
        );
        await _sendGroupMessage(text: "Shared a file", type: 'file', mediaUrl: url, fileName: name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: ${e}")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.charcoalLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.goldPrimary),
              title: const Text("Capture Image"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.goldPrimary),
              title: const Text("Gallery Image"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_rounded, color: AppTheme.goldPrimary),
              title: const Text("Share Video"),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded, color: AppTheme.goldPrimary),
              title: const Text("Share Document"),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoalLight,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.groupAvatar.isNotEmpty ? NetworkImage(widget.groupAvatar) : null,
              backgroundColor: AppTheme.goldPrimary.withOpacity(0.2),
              child: widget.groupAvatar.isEmpty ? const Icon(Icons.group_rounded, color: AppTheme.goldPrimary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.groupName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('VIP Broadcast Room', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Typing indicator stream bar
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection('groups')
                .doc(widget.groupId)
                .collection('typing')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final typers = snapshot.data!.docs
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isTyping = data['isTyping'] ?? false;
                    final isMe = doc.id == authController.currentUser?.uid;
                    return isTyping && !isMe;
                  })
                  .map((doc) => (doc.data() as Map<String, dynamic>)['fullName'] ?? 'Someone')
                  .toList();

              if (typers.isEmpty) return const SizedBox();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.black26,
                width: double.infinity,
                child: Text(
                  "${typers.join(', ')} typing...",
                  style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              );
            },
          ),

          if (_isUploading)
            const LinearProgressIndicator(backgroundColor: AppTheme.charcoalLight, valueColor: AlwaysStoppedAnimation(AppTheme.goldPrimary)),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.goldPrimary)));
                }

                final docs = snapshot.data!.docs;
                final messages = docs.map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "Lounge is active. Broadcast your message.",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  );
                }

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
                        onLongPress: () => _showMessageActions(context, msg),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Show sender name for group clarity
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 18, top: 4, bottom: 2),
                                child: Text(
                                  msg.senderName.isNotEmpty ? msg.senderName : "VIP Elite",
                                  style: const TextStyle(color: AppTheme.goldLight, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
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
                                  Text(
                                    "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: isMe ? AppTheme.charcoalDark.withOpacity(0.5) : Colors.white38, fontSize: 9),
                                  ),
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
                        const Text("Editing group broadcast", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      hintText: _editingMessage != null ? "Update message..." : "Broadcast premium message...",
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
                        await FirebaseService.firestore
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('messages')
                            .doc(editId)
                            .update({'text': text, 'isEdited': true});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Broadcast updated!")));
                      } else {
                        await _sendGroupMessage(text: text);
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
                    msg.fileName.isNotEmpty ? msg.fileName : "document.pdf",
                    style: TextStyle(color: isMe ? AppTheme.charcoalDark : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text("VIP Shared File", style: TextStyle(color: Colors.white38, fontSize: 9)),
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

  void _showMessageActions(BuildContext context, MessageModel msg) {
    final auth = Provider.of<AuthController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.charcoalLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            // Reactions Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              border: const Border(bottom: BorderSide(color: Colors.white10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickReactions.map((emoji) {
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final docRef = FirebaseService.firestore
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('messages')
                          .doc(msg.id);
                      
                      final currentReactions = Map<String, dynamic>.from(msg.reactions);
                      currentReactions[auth.currentUser?.uid ?? 'unknown'] = emoji;
                      
                      await docRef.update({'reactions': currentReactions});
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Translating message...")));
                final translated = await GoogleTranslateService.translateText(text: msg.text, targetLanguageCode: 'es');
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppTheme.charcoalLight,
                      title: const Text("Premium Translation", style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
                      content: Text(translated, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(color: AppTheme.goldPrimary)))
                      ],
                    ),
                  );
                }
              },
            ),
            if (msg.senderId == auth.currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text("Delete Broadcast"),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseService.firestore
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('messages')
                      .doc(msg.id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Broadcast removed.")));
                },
              ),
          ],
        ),
      ),
    );
  }
}
