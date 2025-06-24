import 'package:afrimarket/features/auth/domain/models/user.dart';
import 'package:afrimarket/features/chat/domain/models/message.dart';

enum ChatStatus {
  initial,
  loading,
  active,
  loadingMore,
  sending,
  error,
  disposed,
}

class ChatState {
  final List<Message> messages;
  final User? recipient;
  final User? currentUser;
  final ChatStatus status;
  final String chatId;
  final String? errorMessage;
  final bool hasReachedMax;

  const ChatState({
    this.messages = const [],
    this.recipient,
    this.currentUser,
    this.status = ChatStatus.initial,
    this.chatId = '',
    this.errorMessage,
    this.hasReachedMax = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    User? recipient,
    User? currentUser,
    ChatStatus? status,
    String? chatId,
    String? errorMessage,
    bool? hasReachedMax,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      recipient: recipient ?? this.recipient,
      currentUser: currentUser ?? this.currentUser,
      status: status ?? this.status,
      chatId: chatId ?? this.chatId,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatState &&
      other.messages == messages &&
      other.recipient == recipient &&
      other.currentUser == currentUser &&
      other.status == status &&
      other.chatId == chatId &&
      other.errorMessage == errorMessage &&
      other.hasReachedMax == hasReachedMax;
  }

  @override
  int get hashCode {
    return messages.hashCode ^
      recipient.hashCode ^
      currentUser.hashCode ^
      status.hashCode ^
      chatId.hashCode ^
      errorMessage.hashCode ^
      hasReachedMax.hashCode;
  }
}
