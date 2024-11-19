library table_generator;

export 'src/annotations.dart';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/table_generator.dart';

Builder tableBuilder(BuilderOptions options) =>
    SharedPartBuilder([TableGenerator()], 'table_generator');
