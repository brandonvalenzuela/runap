class QuestionModel {
  final String id;
  final String text;
  final String type; // Ejemplo: 'multiple_choice', 'single_choice', 'text'
  final List<String>? options; // Opciones para preguntas de opción múltiple/única
  final String? unit; // Añadir parámetro opcional para unidad (kg, cm)
  final String? imagePath; // Añadir path para imagen opcional
  final String? sectionTitle; // Añadir título de sección opcional

  QuestionModel({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.unit, // Añadir al constructor
    this.imagePath, // Añadir al constructor
    this.sectionTitle, // Añadir al constructor
  });

  // Podríamos añadir aquí métodos fromJson/toJson para la futura API
} 