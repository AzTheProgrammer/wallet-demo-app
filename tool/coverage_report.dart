import 'dart:convert';
import 'dart:io';

class FileCoverage {
  FileCoverage(this.path);

  final String path;
  int lines = 0;
  int hit = 0;

  double get percent => lines == 0 ? 100 : hit * 100 / lines;

  String get layer {
    if (path.contains('/domain/')) return 'domain';
    if (path.contains('/data/')) return 'data';
    if (path.contains('/presentation/') ||
        path.contains('/widgets/') ||
        path.contains('/router/')) {
      return 'presentation';
    }
    return 'other';
  }
}

final _generated = RegExp(r'\.(g|freezed|config)\.dart$');

List<FileCoverage> readCoverage(File file) {
  final files = <FileCoverage>[];
  FileCoverage? current;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).replaceAll(r'\', '/');
      current = _generated.hasMatch(path) ? null : FileCoverage(path);
      if (current != null) files.add(current);
    } else if (line.startsWith('DA:') && current != null) {
      current.lines++;
      if (int.parse(line.substring(3).split(',')[1]) > 0) current.hit++;
    }
  }
  return files..sort((a, b) => a.percent.compareTo(b.percent));
}

String row(String name, int hit, int lines) {
  final percent = lines == 0 ? 100.0 : hit * 100 / lines;
  final escaped = const HtmlEscape().convert(name);
  return '<tr><td>$escaped</td><td>$hit / $lines</td> '
      '<td>${percent.toStringAsFixed(1)}%</td></tr>';
}

String page(Map<String, List<int>> layers, List<FileCoverage> files) =>
    '''
<!doctype html>
<meta charset="utf-8">
<title>Wallet coverage</title>
<style>
  body { font: 14px system-ui, sans-serif; margin: 32px auto; max-width: 860px; padding: 0 16px; }
  table { border-collapse: collapse; margin-bottom: 32px; width: 100%; }
  td, th { border-bottom: 1px solid #e1e7e3; padding: 6px 8px; text-align: left; }
  td:nth-child(n+2), th:nth-child(n+2) { text-align: right; white-space: nowrap; }
</style>
<h1>Wallet coverage</h1>
<h2>By layer</h2>
<table>
<tr><th>Layer</th><th>Lines</th><th>Coverage</th></tr>
${layers.entries.map((e) => row(e.key, e.value[1], e.value[0])).join('\n')}
</table>
<h2>By file, lowest first</h2>
<table>
<tr><th>File</th><th>Lines</th><th>Coverage</th></tr>
${files.map((f) => row(f.path, f.hit, f.lines)).join('\n')}
</table>
''';

void main() {
  final source = File('coverage/lcov.info');
  if (!source.existsSync()) {
    stderr.writeln('coverage/lcov.info not found. Run make coverage.');
    exitCode = 1;
    return;
  }
  final files = readCoverage(source);
  final layers = <String, List<int>>{};
  for (final file in files) {
    final totals = layers.putIfAbsent(file.layer, () => [0, 0]);
    totals[0] += file.lines;
    totals[1] += file.hit;
  }
  for (final MapEntry(key: layer, value: totals) in layers.entries) {
    final percent = totals[0] == 0 ? 100 : totals[1] * 100 / totals[0];
    stdout.writeln('${layer.padRight(14)}${percent.toStringAsFixed(1)}%');
  }
  File('coverage/index.html').writeAsStringSync(page(layers, files));
  stdout.writeln('Report: coverage/index.html');
}
