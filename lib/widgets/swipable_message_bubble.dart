import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/chat_service.dart';

/// A swipable message bubble widget that provides gesture-based actions.
/// 
/// This widget wraps a message bubble with swipe functionality to provide
/// quick access to common message actions:
/// - Left swipe: Reply to message
/// - Right swipe: More actions (edit/delete)
/// 
/// Features:
/// - Smooth animations with haptic feedback
/// - Different action sets based on message ownership
/// - Visual feedback during swipe gestures
/// - Automatic reset after action completion
/// 
/// Example usage:
/// ```dart
/// SwipableMessageBubble(
///   message: chatMessage,
///   isMe: true,
///   child: MessageBubbleWidget(),
///   onReply: (message) => handleReply(message),
///   onEdit: (message) => handleEdit(message),
///   onDelete: (message) => handleDelete(message),
/// )
/// ```
class SwipableMessageBubble extends StatefulWidget {
  /// The message this bubble represents
  final ChatMessage message;
  
  /// Whether this message was sent by the current user
  final bool isMe;
  
  /// The actual message bubble widget to display
  final Widget child;
  
  /// Callback when user swipes to reply
  final Function(ChatMessage)? onReply;
  
  /// Callback when user swipes to edit (only for own messages)
  final Function(ChatMessage)? onEdit;
  
  /// Callback when user swipes to delete (only for own messages)
  final Function(ChatMessage)? onDelete;
  
  /// Callback when user performs more actions
  final Function(ChatMessage)? onMoreActions;
  
  /// Whether swipe actions are enabled
  final bool enableSwipeActions;
  
  /// The threshold distance for triggering an action
  final double actionThreshold;

  const SwipableMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.child,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onMoreActions,
    this.enableSwipeActions = true,
    this.actionThreshold = 80.0,
  });

  @override
  State<SwipableMessageBubble> createState() => _SwipableMessageBubbleState();
}

class _SwipableMessageBubbleState extends State<SwipableMessageBubble>
    with TickerProviderStateMixin {
  /// Animation controller for swipe animations
  late AnimationController _animationController;
  
  /// Animation for the action button scale
  late Animation<double> _scaleAnimation;
  
  /// Current horizontal pan offset
  double _panOffset = 0.0;
  
  /// Whether an action has been triggered
  bool _actionTriggered = false;
  
  /// The type of action being performed
  SwipeAction? _activeAction;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Sets up the animation controllers and animations
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  /// Handles horizontal pan updates (swipe gestures)
  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeActions) return;

    setState(() {
      _panOffset += details.delta.dx;
      
      // Limit the pan offset to reasonable bounds
      _panOffset = _panOffset.clamp(-120.0, 120.0);
      
      // Determine which action is being triggered
      if (_panOffset.abs() > widget.actionThreshold) {
        final newAction = _panOffset > 0 ? SwipeAction.reply : SwipeAction.moreActions;
        
        if (_activeAction != newAction) {
          _activeAction = newAction;
          _triggerHapticFeedback();
        }
      } else {
        _activeAction = null;
      }
    });
  }

  /// Handles the end of pan gestures
  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableSwipeActions) return;

    if (_panOffset.abs() > widget.actionThreshold && !_actionTriggered) {
      _actionTriggered = true;
      _performAction();
    } else {
      _resetPosition();
    }
  }

  /// Performs the appropriate action based on swipe direction
  void _performAction() {
    if (_activeAction == SwipeAction.reply) {
      _triggerHapticFeedback();
      widget.onReply?.call(widget.message);
    } else if (_activeAction == SwipeAction.moreActions) {
      _triggerHapticFeedback();
      if (widget.isMe) {
        // Show edit/delete options for own messages
        widget.onMoreActions?.call(widget.message);
      } else {
        // Show other options for received messages
        widget.onMoreActions?.call(widget.message);
      }
    }
    
    _resetPosition();
  }

  /// Resets the bubble position with animation
  void _resetPosition() {
    _animationController.forward().then((_) {
      setState(() {
        _panOffset = 0.0;
        _activeAction = null;
        _actionTriggered = false;
      });
      _animationController.reset();
    });
  }

  /// Triggers haptic feedback for better user experience
  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Builds the action buttons that appear during swipe
  Widget _buildActionButtons() {
    if (_activeAction == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Row(
        children: [
          // Left side action (reply)
          if (_activeAction == SwipeAction.reply)
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.reply,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          
          if (_activeAction == SwipeAction.reply) const Spacer(),
          
          // Right side action (more actions)
          if (_activeAction == SwipeAction.moreActions) const Spacer(),
          
          if (_activeAction == SwipeAction.moreActions)
            Expanded(
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.orange.shade600 : Colors.grey.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isMe ? Icons.edit : Icons.more_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Action buttons background
          _buildActionButtons(),
          
          // The actual message bubble
          Transform.translate(
            offset: Offset(_panOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Enum representing different swipe actions
enum SwipeAction {
  /// Reply to the message
  reply,
  
  /// Show more actions (edit/delete for own messages, other options for received)
  moreActions,
}