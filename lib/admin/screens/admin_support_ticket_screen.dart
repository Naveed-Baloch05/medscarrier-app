import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_support/admin_support_bloc.dart';
import '../../bloc/admin_support/admin_support_event.dart';
import '../../models/support_ticket_model.dart';

class AdminSupportTicketScreen extends StatefulWidget {
  const AdminSupportTicketScreen({super.key, required this.ticket});

  final SupportTicketModel ticket;

  @override
  State<AdminSupportTicketScreen> createState() =>
      _AdminSupportTicketScreenState();
}

class _AdminSupportTicketScreenState extends State<AdminSupportTicketScreen> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final AdminSupportBloc _bloc;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _bloc = context.read<AdminSupportBloc>();
    _bloc.add(AdminSupportMarkRead(widget.ticket.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _bloc.add(AdminSupportSendMessage(
      ticketId: widget.ticket.id,
      message: text,
    ));
    _controller.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardBg = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final isOpen = widget.ticket.status == 'open';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.subject,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                        : const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.ticket.senderType.toUpperCase()} - ${widget.ticket.senderName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textPrimary),
            onSelected: (value) {
              if (value == 'close' && isOpen) {
                _bloc.add(AdminSupportCloseTicket(widget.ticket.id));
                Navigator.pop(context);
              } else if (value == 'reopen' && !isOpen) {
                _bloc.add(AdminSupportReopenTicket(widget.ticket.id));
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuItem<String>>[];
              if (isOpen) {
                items.add(const PopupMenuItem(
                  value: 'close',
                  child: Text('Close Ticket'),
                ));
              } else {
                items.add(const PopupMenuItem(
                  value: 'reopen',
                  child: Text('Reopen Ticket'),
                ));
              }
              return items;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessageModel>>(
              stream: _bloc.streamMessages(widget.ticket.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAdmin = msg.senderType == 'admin';
                    return _MessageBubble(
                      message: msg,
                      isAdmin: isAdmin,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      primaryColor: primaryColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
          if (isOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF14261E)
                            : const Color(0xFFF2F5F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your response...',
                          hintStyle: TextStyle(
                            color: textSecondary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'This ticket is closed',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isAdmin,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.borderColor,
    required this.isDark,
  });

  final SupportMessageModel message;
  final bool isAdmin;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color borderColor;
  final bool isDark;

  String _formatTime(DateTime date) {
    final h = date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    if (msgDay == today) return 'Today';
    if (msgDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final align = isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isAdmin
        ? primaryColor
        : (isDark ? const Color(0xFF1A2720) : const Color(0xFFF0F0F0));
    final textColor = isAdmin ? Colors.white : textPrimary;
    final subColor = isAdmin
        ? Colors.white.withValues(alpha: 0.7)
        : textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.75).clamp(0, 360),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                bottomRight: Radius.circular(isAdmin ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(message.createdAt)} ${_formatTime(message.createdAt)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
