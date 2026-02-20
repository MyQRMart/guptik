class WhatsAppTemplate {
  final String id;
  final String name;
  final String language;
  final String status;
  final String category;
  final List<TemplateComponent> components;

  WhatsAppTemplate({
    required this.id,
    required this.name,
    required this.language,
    required this.status,
    required this.category,
    required this.components,
  });

  factory WhatsAppTemplate.fromJson(Map<String, dynamic> json) {
    var componentList = json['components'] as List? ?? [];
    return WhatsAppTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      language: json['language'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      category: json['category'] ?? '',
      components: componentList
          .map((c) => TemplateComponent.fromJson(c))
          .toList(),
    );
  }

  TemplateComponent? get header =>
      components.where((c) => c.type == 'HEADER').firstOrNull;
  TemplateComponent? get body =>
      components.where((c) => c.type == 'BODY').firstOrNull;

  int get requiredBodyVariables {
    if (body == null || body!.text.isEmpty) return 0;
    final regExp = RegExp(r'\{\{(\d+)\}\}');
    return regExp.allMatches(body!.text).length;
  }
}

class TemplateComponent {
  final String type;
  final String format;
  final String text;

  TemplateComponent({
    required this.type,
    required this.format,
    required this.text,
  });

  factory TemplateComponent.fromJson(Map<String, dynamic> json) {
    return TemplateComponent(
      type: json['type'] ?? '',
      format: json['format'] ?? '',
      text: json['text'] ?? '',
    );
  }
}
