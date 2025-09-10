import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobiking/app/controllers/query_getx_controller.dart'; // ✅ ADDED BACK
import 'package:mobiking/app/themes/app_theme.dart';

import '../../../data/QueryModel.dart';
import '../../../data/order_model.dart';

class QueryDetailScreen extends StatefulWidget {
  final OrderModel? order;

  const QueryDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> with TickerProviderStateMixin {
  late final QueryModel? currentQuery;
  final TextEditingController _replyInputController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isTextFieldFocused = false;
  bool _isSending = false; // ✅ ADDED: To manage loading state for the send button
  late AnimationController _messageAnimationController;
  late Animation<double> _messageAnimation;

  @override
  void initState() {
    super.initState();
    currentQuery = widget.order?.query;
    _initializeAnimations();
    _setupFocusListener();
  }

  void _initializeAnimations() {
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _messageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageAnimationController, curve: Curves.easeInOut),
    );
    _messageAnimationController.forward();
  }

  void _setupFocusListener() {
    _textFieldFocusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _textFieldFocusNode.hasFocus;
      });
    });
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _messageAnimationController.dispose();
    _replyInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'Query Details',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // You can optionally trigger a refresh via the controller here if needed
              final controller = Get.find<QueryGetXController>();
              if (controller.currentQuery != null) {
                controller.refreshCurrentQuery();
                Get.snackbar("Syncing", "Refreshing conversation...", snackPosition: SnackPosition.BOTTOM);
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // The main view logic still depends on the initial data
          if (currentQuery == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'No Query Found',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No query has been raised for this order yet.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showCreateQueryDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Create Query'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOrderInfoCard(widget.order, textTheme),
                    _buildQueryDetailsCard(currentQuery, textTheme),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildConversationHeader(textTheme),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightGreyBackground, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        // Using Obx & controller here to get real-time message updates after sending
                        child: Obx(() {
                          final liveQuery = Get.find<QueryGetXController>().currentQuery ?? currentQuery;
                          return _buildConversationListFromQuery(liveQuery!, textTheme);
                        }
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (currentQuery?.status != 'resolved') _buildMessageInput(textTheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationListFromQuery(QueryModel query, TextTheme textTheme) {
    final initialMessage = ReplyModel(
      userId: query.userEmail,
      replyText: query.message,
      timestamp: query.raisedAt ?? query.createdAt,
      isAdmin: false,
    );

    final fullConversation = [initialMessage, ...query.replies];
    return _buildConversationList(fullConversation, textTheme);
  }

  Widget _buildConversationHeader(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: AppColors.primaryPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            'Conversation',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (currentQuery?.status != 'resolved')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Active',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel? order, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple,
            AppColors.primaryPurple.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.shopping_bag, color: AppColors.white, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Order Details',
                        style: textTheme.titleMedium
                            ?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                    Text('Query related to this order',
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.white.withOpacity(0.8)))
                  ]))
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _buildOrderInfoItem(
                      'Order ID', order?.orderId ?? 'N/A', textTheme)),
              Expanded(
                  child: _buildOrderInfoItem('Amount',
                      '₹${order?.orderAmount.toStringAsFixed(0) ?? 'N/A'}', textTheme))
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _buildOrderInfoItem(
                      'Date',
                      order?.createdAt != null
                          ? DateFormat('MMM d, yyyy').format(order!.createdAt)
                          : 'N/A',
                      textTheme)),
              Expanded(
                  child: _buildOrderInfoItem(
                      'Status', order?.status.capitalizeFirst ?? 'N/A', textTheme))
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoItem(String label, String value, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQueryDetailsCard(QueryModel? query, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreyBackground, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    query?.title ?? 'Query Title',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(query?.status ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    query?.status?.capitalizeFirst ?? 'Pending',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(query?.status ?? ''),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              query?.message ?? 'No message available.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Raised ${DateFormat('MMM d, yyyy').format(query?.raisedAt ?? DateTime.now())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (query?.status == 'resolved' && query?.resolvedAt != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved ${DateFormat('MMM d').format(query!.resolvedAt!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(List<dynamic> replies, TextTheme textTheme) {
    if (replies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: AppColors.neutralBackground, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 32, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Text('No messages yet',
                style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Start the conversation by sending a message',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final sortedReplies = List.from(replies);
    sortedReplies.sort((a, b) {
      final dateA = a.timestamp ?? a.createdAt ?? DateTime.now();
      final dateB = b.timestamp ?? b.createdAt ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: sortedReplies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final reply = sortedReplies[index];
        final isUser = !reply.isAdmin;
        return AnimatedBuilder(
          animation: _messageAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _messageAnimation.value),
              child: Opacity(
                opacity: _messageAnimation.value,
                child: _buildMessageBubble(reply, isUser, textTheme),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(dynamic reply, bool isUser, TextTheme textTheme) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryPurple : AppColors.neutralBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Support Team',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                reply.replyText ?? reply.message ?? 'No message',
                style: textTheme.bodyMedium?.copyWith(
                  color: isUser ? AppColors.white : AppColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM d, hh:mm a').format(
                      reply.timestamp ?? reply.createdAt ?? DateTime.now(),
                    ),
                    style: textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? AppColors.white.withOpacity(0.7)
                          : AppColors.textLight,
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.lightGreyBackground, width: 1)),
        boxShadow: _isTextFieldFocused
            ? [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ]
            : null,
      ),
      child: SafeArea(
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neutralBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: _isTextFieldFocused
                      ? Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    width: 1,
                  )
                      : null,
                ),
                child: TextField(
                  controller: _replyInputController,
                  focusNode: _textFieldFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _isSending ? AppColors.textLight : AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
                    : const Icon(Icons.send, color: AppColors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'open':
        return AppColors.danger;
      case 'in_progress':
      case 'pending_reply':
        return AppColors.primaryPurple;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textLight;
      default:
        return AppColors.danger;
    }
  }

  // ✅ MODIFIED: This function now works again.
  void _sendMessage() async {
    if (_replyInputController.text.trim().isEmpty || currentQuery == null) {
      return;
    }

    // Find the controller to perform the action
    final controller = Get.find<QueryGetXController>();
    final textToSend = _replyInputController.text.trim();

    _textFieldFocusNode.unfocus();
    _replyInputController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      await controller.replyToQuery(
        queryId: currentQuery!.id,
        replyText: textToSend,
      );
      // Let the Obx handle the UI update
    } catch (e) {
      // Handle error, maybe show a snackbar
      Get.snackbar("Error", "Failed to send message.");
      // If failed, put the text back for the user to retry
      _replyInputController.text = textToSend;
    } finally {
      setState(() {
        _isSending = false;
      });
      // Scroll to bottom after a short delay to allow UI to update
      Future.delayed(const Duration(milliseconds: 300), () => _scrollToBottom());
    }
  }

  // ✅ MODIFIED: This function now works again.
  void _showCreateQueryDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Query Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty &&
                  messageController.text.trim().isNotEmpty) {
                // Find the controller to perform the action
                final controller = Get.find<QueryGetXController>();
                Get.back(); // Close the dialog first
                await controller.raiseQuery(
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  orderId: widget.order?.id,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}