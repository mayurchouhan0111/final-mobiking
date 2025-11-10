import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobiking/app/controllers/query_getx_controller.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../../../data/QueryModel.dart';
import '../../../data/order_model.dart';
import 'OptimizedMessageInput.dart';

class QueryDetailScreen extends StatefulWidget {
  final OrderModel? order;

  const QueryDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> {
  late final QueryModel? currentQuery;
  final TextEditingController _replyInputController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int? _previousMessageCount;

  bool _isSending = false;

  // 🔥 KEYBOARD STATE TRACKING
  bool _isKeyboardVisible = false;
  bool _isKeyboardAnimating = false;
  double _lastKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    currentQuery = widget.order?.query;

    // 🔥 Pre-warm keyboard to reduce first-open lag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _replyInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // 🔥 TRACK KEYBOARD STATE
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Detect keyboard animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bool wasVisible = _isKeyboardVisible;
      final bool isNowVisible = keyboardHeight > 100;

      // Keyboard opening
      if (!wasVisible && keyboardHeight > 0 && keyboardHeight < 200) {
        if (!_isKeyboardAnimating) {
          setState(() {
            _isKeyboardAnimating = true;
          });
        }
      }
      // Keyboard fully open
      else if (keyboardHeight >= 200 && _isKeyboardAnimating) {
        setState(() {
          _isKeyboardAnimating = false;
          _isKeyboardVisible = true;
        });
      }
      // Keyboard closing
      else if (wasVisible && keyboardHeight < _lastKeyboardHeight && keyboardHeight > 0) {
        if (!_isKeyboardAnimating) {
          setState(() {
            _isKeyboardAnimating = true;
          });
        }
      }
      // Keyboard fully closed
      else if (keyboardHeight == 0 && _isKeyboardAnimating) {
        setState(() {
          _isKeyboardAnimating = false;
          _isKeyboardVisible = false;
        });
      }

      _lastKeyboardHeight = keyboardHeight;
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              final controller = Get.find<QueryGetXController>();
              if (controller.currentQuery != null) {
                controller.refreshCurrentQuery();
                Get.snackbar(
                  "Syncing",
                  "Refreshing conversation...",
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              }
            },
          ),
        ],
      ),
      body: currentQuery == null
          ? _buildNoQueryView(textTheme)
          : SafeArea(
            child: Column(
                    children: [
            // 🔥 WRAPPED IN REPAINT BOUNDARY
            RepaintBoundary(
              child: _OrderInfoSection(order: widget.order, query: currentQuery),
            ),
            
            RepaintBoundary(
              child: _buildConversationHeader(textTheme),
            ),
            
            Expanded(
              child: RepaintBoundary(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightGreyBackground, width: 1),
                  ),
                  child: Obx(() {
                    final liveQuery =
                        Get.find<QueryGetXController>().currentQuery ?? currentQuery;
                    return _buildConversationListFromQuery(liveQuery!, textTheme);
                  }),
                ),
              ),
            ),
            
            // 🔥 SHOW/HIDE INPUT BASED ON KEYBOARD STATE
            if (currentQuery?.status != 'resolved')
              Visibility(
                visible: !_isKeyboardAnimating,
                maintainSize: false,
                maintainAnimation: false,
                maintainState: true,
                child: OptimizedMessageInput(
                  controller: _replyInputController,
                  focusNode: _textFieldFocusNode,
                  isSending: _isSending,
                  onSend: _sendMessage,
                ),
              ),
                    ],
                  ),
          ),
    );
  }

  Widget _buildNoQueryView(TextTheme textTheme) {
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
                color: AppColors.neutralBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 32,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation by sending a message',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final sortedReplies = List<dynamic>.from(replies);
    sortedReplies.sort((a, b) {
      final dateA = a.timestamp ?? a.createdAt ?? DateTime.now();
      final dateB = b.timestamp ?? b.createdAt ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    // 🔥 ONLY scroll on new messages, not on keyboard open
    if (sortedReplies.length > (_previousMessageCount ?? 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
      _previousMessageCount = sortedReplies.length;
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: sortedReplies.length,
      physics: const ClampingScrollPhysics(),
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final reply = sortedReplies[index];
        final isUser = !reply.isAdmin;
        return Padding(
          key: ValueKey(reply.timestamp ?? index),
          padding: EdgeInsets.only(bottom: index < sortedReplies.length - 1 ? 16 : 0),
          child: _MessageBubble(reply: reply, isUser: isUser),
        );
      },
    );
  }

  void _sendMessage() async {
    if (_replyInputController.text.trim().isEmpty || currentQuery == null) {
      return;
    }

    final controller = Get.find<QueryGetXController>();
    final textToSend = _replyInputController.text.trim();

    FocusScope.of(context).unfocus();
    _replyInputController.clear();

    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      await controller.replyToQuery(
        queryId: currentQuery!.id,
        replyText: textToSend,
      );

      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Error",
          "Failed to send message.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        _replyInputController.text = textToSend;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

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
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autocorrect: false,
              enableSuggestions: false,
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
                final controller = Get.find<QueryGetXController>();
                Get.back();
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

// 🔥 OPTIMIZED: RepaintBoundary + removed SingleChildScrollView
class _OrderInfoSection extends StatelessWidget {
  final OrderModel? order;
  final QueryModel? query;

  const _OrderInfoSection({required this.order, required this.query});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOrderInfoCard(order, textTheme),
        _buildQueryDetailsCard(query, textTheme),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOrderInfoCard(OrderModel? order, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Query related to this order',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfoItem('Order ID', order?.orderId ?? 'N/A', textTheme),
                ),
                Expanded(
                  child: _buildOrderInfoItem(
                    'Amount',
                    '₹${order?.orderAmount.toStringAsFixed(0) ?? 'N/A'}',
                    textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfoItem(
                    'Date',
                    order?.createdAt != null
                        ? DateFormat('MMM d, yyyy').format(order!.createdAt)
                        : 'N/A',
                    textTheme,
                  ),
                ),
                Expanded(
                  child: _buildOrderInfoItem(
                    'Status',
                    order?.status.capitalizeFirst ?? 'N/A',
                    textTheme,
                  ),
                ),
              ],
            )
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
}

// 🔥 OPTIMIZED: RepaintBoundary on each bubble
class _MessageBubble extends StatelessWidget {
  final dynamic reply;
  final bool isUser;

  const _MessageBubble({required this.reply, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RepaintBoundary(
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primaryPurple : AppColors.neutralBackground,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
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
                        color: isUser ? AppColors.white.withOpacity(0.7) : AppColors.textLight,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.white.withOpacity(0.7),
                      ),
                    ],
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