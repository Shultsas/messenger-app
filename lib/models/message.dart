class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final String? senderName;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl = '',
    required this.createdAt,
    this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      chatId: json['chatId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      senderName: json['SenderName'] ?? json['senderName'] ?? 'User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'senderName': senderName,
    };
  }
}