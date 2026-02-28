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

  const QueryDetailScreen({Key? key, required this.order}) : super(key: key);

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

  bool _isOffHours() {
    final now = DateTime.now();
    // Business hours: Mon-Sat, 10:00 AM to 7:00 PM IST (GMT+5:30 approximate)
    if (now.hour < 10 || now.hour >= 19) return true;
    if (now.weekday == DateTime.sunday) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    final controller = Get.find<QueryGetXController>();
    currentQuery = widget.order?.query;
    
    if (currentQuery != null) {
      controller.setCurrentQuery(currentQuery!);
    } else if (widget.order?.id != null) {
      controller.fetchQueryByOrderId(widget.order!.id);
    }

    // 🔥 Listen to keyboard focus to scroll up smoothly like WhatsApp
    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus) {
        _scrollToBottom(animated: true);
      }
    });
  }

  @override
  void dispose() {
    Get.find<QueryGetXController>().clearCurrentQuery();
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _replyInputController.dispose();
    super.dispose();
  }

  // Helper method to handle scrolling
  void _scrollToBottom({bool animated = false}) {
    // Delay allows the keyboard animation to complete and Scaffold to resize
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  backgroundColor: AppColors.primaryPurple,
                  colorText: AppColors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final controller = Get.find<QueryGetXController>();
        final liveQuery = controller.currentQuery ?? currentQuery;

        if (liveQuery == null) {
          return _buildNoQueryView(textTheme);
        }

        final initialMessage = ReplyModel(
          userId: liveQuery.userEmail,
          replyText: liveQuery.message,
          timestamp: liveQuery.raisedAt ?? liveQuery.createdAt,
          isAdmin: false,
        );

        final List<dynamic> fullConversation = [
          initialMessage,
          ...liveQuery.replies,
        ];
        fullConversation.sort((a, b) {
          final dateA = a.timestamp ?? a.createdAt ?? DateTime.now();
          final dateB = b.timestamp ?? b.createdAt ?? DateTime.now();
          return dateA.compareTo(dateB);
        });

        // Detect new messages and scroll accordingly
        if (fullConversation.length > (_previousMessageCount ?? 0)) {
          final isInitialLoad =
              _previousMessageCount == null || _previousMessageCount == 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(animated: !isInitialLoad);
          });
          _previousMessageCount = fullConversation.length;
        }

        return Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent:
                      1000, // Pre-render some bubbles for smoother scrolling
                  slivers: [
                    SliverToBoxAdapter(
                      child: _OrderInfoSection(
                        order: widget.order,
                        query: liveQuery,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SimpleSliverHeaderDelegate(
                        child: Container(
                          color: AppColors.neutralBackground,
                          child: _buildConversationHeader(textTheme),
                        ),
                        maxHeight: 50,
                        minHeight: 50,
                      ),
                    ),
                    if (_isOffHours())
                      SliverToBoxAdapter(
                        child: _buildOffHoursBanner(textTheme),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final reply = fullConversation[index];
                          final isUser = !reply.isAdmin;
                          return Padding(
                            key: ValueKey(
                              reply.timestamp?.millisecondsSinceEpoch ?? index,
                            ),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _MessageBubble(reply: reply, isUser: isUser),
                          );
                        }, childCount: fullConversation.length),
                      ),
                    ),
                    // Padding at the bottom so the last message isn't hidden by the input
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
            ),
            if (liveQuery.status != 'resolved')
              SafeArea(
                top: false,
                child: OptimizedMessageInput(
                  controller: _replyInputController,
                  focusNode: _textFieldFocusNode,
                  isSending: _isSending,
                  onSend: _sendMessage,
                ),
              ),
          ],
        );
      }),
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
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
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

  Widget _buildOffHoursBanner(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.accentOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Offline',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Support is available Mon-Sat, 10am-7pm. We\'ll respond soon.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.accentOrange.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHeader(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.primaryPurple,
            size: 20,
          ),
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

      _scrollToBottom(animated: true);
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
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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

class _SimpleSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;
  final double minHeight;

  _SimpleSliverHeaderDelegate({
    required this.child,
    required this.maxHeight,
    required this.minHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _SimpleSliverHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}

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
                  child: const Icon(
                    Icons.shopping_bag,
                    color: AppColors.white,
                    size: 20,
                  ),
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
                  child: _buildOrderInfoItem(
                    'Order ID',
                    order?.orderId ?? 'N/A',
                    textTheme,
                  ),
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
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      query?.status ?? '',
                    ).withOpacity(0.1),
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
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Raised ${DateFormat('MMM d, yyyy').format(query?.raisedAt ?? DateTime.now())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (query?.status == 'resolved' &&
                    query?.resolvedAt != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
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
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primaryPurple
                : AppColors.neutralBackground,
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
                        color: isUser
                            ? AppColors.white.withOpacity(0.7)
                            : AppColors.textLight,
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
