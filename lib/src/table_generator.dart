import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:table_generator/src/annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'dart:async';

class SyncingTableGenerator extends GeneratorForAnnotation<Entity> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw 'Generator only supports classes.';
    }

    final classElement = element as ClassElement;
    final className = classElement.displayName;

    // Collect fields
    final fields = <String, String>{};
    String? primaryKeyField;
    for (var field in classElement.fields) {
      if (field.isStatic) continue;
      final fieldName = field.name;
      final fieldType = field.type.getDisplayString(withNullability: false);
      fields[fieldName] = fieldType;
      if (field.metadata.any(
          (e) => e.element?.enclosingElement?.displayName == 'PrimaryKey')) {
        primaryKeyField = fieldName;
      }
    }

    if (primaryKeyField == null) {
      throw 'No field annotated with @PrimaryKey in class $className.';
    }

    // Generate createTableSql() method
    final buffer = StringBuffer();

    buffer.writeln('extension ${className}Extension on $className {');
    buffer.writeln('  static String createTableSql() {');
    buffer.write(
        "    return 'CREATE TABLE IF NOT EXISTS ${_tableName(className)} (");

    final fieldDefs = fields.entries.map((entry) {
      final fieldName = entry.key;
      final fieldType = _sqlType(entry.value);
      final isPrimaryKey = fieldName == primaryKeyField ? ' PRIMARY KEY' : '';
      return '$fieldName $fieldType$isPrimaryKey';
    }).join(', ');

    buffer.write('$fieldDefs);');
    buffer.writeln("';");
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _tableName(String className) {
    // Convert class name to table name (e.g., 'SyncingTable' to 'syncing_table')
    final regExp = RegExp(r'(?<=[a-z])[A-Z]');
    return className
        .replaceAllMapped(regExp, (match) => '_${match.group(0)}')
        .toLowerCase();
  }

  String _sqlType(String dartType) {
    // Map Dart types to SQL types
    switch (dartType) {
      case 'int':
        return 'INTEGER';
      case 'double':
        return 'REAL';
      case 'String':
        return 'TEXT';
      case 'bool':
        return 'INTEGER'; // SQLite does not have a separate Boolean storage class.
      default:
        return 'TEXT'; // Default to TEXT for other types.
    }
  }
}
