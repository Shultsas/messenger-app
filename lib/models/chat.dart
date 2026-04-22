class Chat {
  final int id;
  final String name;
  final bool isGroup;

  Chat({
    required this.id,
    required this.name,
    required this.isGroup,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Chat',
      isGroup: json['isGroup'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isGroup': isGroup,
    };
  }
}