import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;
  final String? senderName;
  final String? avatarUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
    this.senderName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderName != null && !isMe)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 4),
                child: Text(
                  senderName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe && avatarUrl != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(avatarUrl!),
                  ),
                if (!isMe && avatarUrl == null)
                  CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 18),
                  ),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: isMe ? 0 : 8,
                      right: isMe ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            Radius.circular(isMe ? 16 : 0),
                        bottomRight:
                            Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMe
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isMe
                                    ? colorScheme.onPrimary.withOpacity(0.7)
                                    : colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 12,
                                color: isRead
                                    ? colorScheme.primaryContainer
                                    : colorScheme.onPrimary.withOpacity(0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}