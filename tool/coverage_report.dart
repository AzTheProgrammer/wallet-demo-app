import 'dart:convert';
import 'dart:io';

const _escape = HtmlEscape(HtmlEscapeMode.element);
const _attribute = HtmlEscape(HtmlEscapeMode.attribute);

class Totals {
  int lines = 0;
  int hit = 0;

  double get percent => lines == 0 ? 100 : hit * 100 / lines;

  void add(FileCoverage file) {
    lines += file.lines;
    hit += file.hit;
  }
}

class FileCoverage {
  FileCoverage(this.path);

  final String path;
  final hits = <int, int>{};

  int get lines => hits.length;
  int get hit => hits.values.where((count) => count > 0).length;
  double get percent => lines == 0 ? 100 : hit * 100 / lines;
  String get name => path.substring(path.lastIndexOf('/') + 1);
  String get folder => path.substring(0, path.lastIndexOf('/'));
  String get pageName => '${path.replaceAll('/', '__')}.html';

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
      final parts = line.substring(3).split(',');
      current.hits[int.parse(parts[0])] = int.parse(parts[1]);
    }
  }
  return files..sort(_lowestFirst);
}

int _lowestFirst(FileCoverage a, FileCoverage b) {
  final byPercent = a.percent.compareTo(b.percent);
  return byPercent != 0 ? byPercent : a.path.compareTo(b.path);
}

const _style = '''
<style>
  :root {
    --bg: #fbfcfb; --fg: #17211d; --muted: #5d6b65; --line: #e1e7e3; --link: #0b6b52;
    --good: #0b7a5e; --warn: #b7791f; --bad: #c0392b; --track: #e6ebe8;
    --hit-bg: #e4f4ed; --miss-bg: #fbe5e2; --target: #fff3c4;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #111815; --fg: #e4ebe7; --muted: #94a39c; --line: #2a3531; --link: #5fd0ad;
      --good: #3cbf97; --warn: #e0a94a; --bad: #ef7464; --track: #27322d;
      --hit-bg: #163329; --miss-bg: #41201c; --target: #4a4117;
      color-scheme: dark;
    }
  }
  body { background: var(--bg); color: var(--fg); font: 14px system-ui, sans-serif; margin: 32px auto; max-width: 1040px; padding: 0 16px; }
  a { color: var(--link); }
  h1 { font-size: 22px; margin: 0 0 4px; overflow-wrap: anywhere; }
  h2 { font-size: 16px; margin: 32px 0 8px; }
  .crumbs, .summary { color: var(--muted); margin: 0 0 16px; overflow-wrap: anywhere; }
  .scroll { overflow-x: auto; }
  table { border-collapse: collapse; width: 100%; }
  .list td, .list th { border-bottom: 1px solid var(--line); padding: 6px 8px; text-align: left; }
  .list td:nth-child(n+2), .list th:nth-child(n+2) { text-align: right; white-space: nowrap; }
  .list td:first-child { overflow-wrap: anywhere; }
  .bar { background: var(--track); border-radius: 3px; display: inline-block; height: 8px; overflow: hidden; vertical-align: middle; width: 96px; }
  .bar i { display: block; height: 100%; }
  .good i { background: var(--good); }
  .warn i { background: var(--warn); }
  .bad i { background: var(--bad); }
  .source { font: 12.5px/1.5 ui-monospace, Consolas, monospace; }
  .source td { padding: 0 8px; white-space: pre; }
  .source .no, .source .count { color: var(--muted); text-align: right; user-select: none; width: 1%; }
  .source .no a { color: inherit; text-decoration: none; }
  .source .hit td { background: var(--hit-bg); }
  .source .miss td { background: var(--miss-bg); }
  .source tr:target td { background: var(--target); }
</style>
''';

String shell(String title, String crumbs, String body) =>
    '''
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_escape.convert(title)}</title>
$_style
<p class="crumbs">$crumbs</p>
$body
''';

String link(String href, String text) =>
    '<a href="${_attribute.convert(href)}">${_escape.convert(text)}</a>';

String bar(double percent) {
  final band = percent >= 90
      ? 'good'
      : percent >= 75
      ? 'warn'
      : 'bad';
  final width = percent.toStringAsFixed(1);
  return '<span class="bar $band"><i style="width:$width%"></i></span>';
}

String row(String label, int hit, int lines) {
  final percent = lines == 0 ? 100.0 : hit * 100 / lines;
  final cells = [
    label,
    '$hit / $lines',
    '${percent.toStringAsFixed(1)}%',
    bar(percent),
  ];
  return '<tr>${cells.map((cell) => '<td>$cell</td>').join()}</tr>';
}

String table(String heading, List<String> rows) =>
    '''
<div class="scroll"><table class="list">
<tr><th>$heading</th><th>Lines</th><th>Coverage</th><th></th></tr>
${rows.join('\n')}
</table></div>
''';

String folderPageName(String folder) =>
    'folder_${folder.replaceAll('/', '__')}.html';

String indexPage(
  Totals total,
  Map<String, Totals> layers,
  Map<String, List<FileCoverage>> folders,
  List<FileCoverage> files,
) {
  final layerRows = layers.entries.map(
    (e) => row(
      link('pages/layer_${e.key}.html', e.key),
      e.value.hit,
      e.value.lines,
    ),
  );
  final folderRows = folders.entries.map((e) {
    final totals = Totals();
    e.value.forEach(totals.add);
    return row(
      link('pages/${folderPageName(e.key)}', e.key),
      totals.hit,
      totals.lines,
    );
  });
  final fileRows = files.map(
    (f) => row(link('pages/${f.pageName}', f.path), f.hit, f.lines),
  );
  return shell('Wallet coverage', 'Generated code is left out.', '''
<h1>Wallet coverage</h1>
<p class="summary">${total.percent.toStringAsFixed(1)}% of lines, ${total.hit} of ${total.lines}</p>
<h2>By layer</h2>
${table('Layer', layerRows.toList())}
<h2>By folder</h2>
${table('Folder', folderRows.toList())}
<h2>By file, lowest first</h2>
${table('File', fileRows.toList())}
''');
}

String listPage(String title, List<FileCoverage> files) {
  final totals = Totals();
  files.forEach(totals.add);
  final rows = files.map(
    (f) => row(link(f.pageName, f.path), f.hit, f.lines),
  );
  return shell(
    '$title coverage',
    '${link('../index.html', 'Wallet coverage')} / ${_escape.convert(title)}',
    '''
<h1>${_escape.convert(title)}</h1>
<p class="summary">${totals.percent.toStringAsFixed(1)}% of lines, ${totals.hit} of ${totals.lines}</p>
${table('File', rows.toList())}
''',
  );
}

String filePage(FileCoverage file) {
  final source = File(file.path);
  final crumbs =
      '${link('../index.html', 'Wallet coverage')} / '
      '${link(folderPageName(file.folder), file.folder)} / '
      '${_escape.convert(file.name)}';
  final missed = file.hits.entries.where((e) => e.value == 0).map((e) => e.key);
  final firstMissed = missed.isEmpty
      ? null
      : missed.reduce((a, b) => a < b ? a : b);
  final jump = firstMissed == null
      ? 'No missed lines'
      : '${missed.length} missed, ${link('#L$firstMissed', 'jump to the first')}';
  final summary =
      '${file.percent.toStringAsFixed(1)}% of lines, '
      '${file.hit} of ${file.lines}. $jump';
  final buffer = StringBuffer();
  if (source.existsSync()) {
    final lines = source.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final number = i + 1;
      final count = file.hits[number];
      final kind = count == null
          ? ''
          : count > 0
          ? ' class="hit"'
          : ' class="miss"';
      final cells = [
        '<td class="no"><a href="#L$number">$number</a></td>',
        '<td class="count">${count ?? ''}</td>',
        '<td>${_escape.convert(lines[i])}</td>',
      ];
      buffer.writeln('<tr id="L$number"$kind>${cells.join()}</tr>');
    }
  }
  final body = buffer.isEmpty
      ? '<p>Source file not found.</p>'
      : '<div class="scroll"><table class="source">\n$buffer</table></div>';
  return shell('${file.name} coverage', crumbs, '''
<h1>${_escape.convert(file.name)}</h1>
<p class="summary">$summary</p>
$body
''');
}

void main() {
  final source = File('coverage/lcov.info');
  if (!source.existsSync()) {
    stderr.writeln('coverage/lcov.info not found. Run make coverage.');
    exitCode = 1;
    return;
  }
  final files = readCoverage(source);
  final total = Totals();
  final layers = <String, Totals>{};
  final byLayer = <String, List<FileCoverage>>{};
  final folders = <String, List<FileCoverage>>{};
  for (final file in files) {
    total.add(file);
    layers.putIfAbsent(file.layer, Totals.new).add(file);
    byLayer.putIfAbsent(file.layer, () => []).add(file);
    folders.putIfAbsent(file.folder, () => []).add(file);
  }
  for (final MapEntry(key: layer, value: totals) in layers.entries) {
    stdout.writeln(
      '${layer.padRight(14)}${totals.percent.toStringAsFixed(1)}%',
    );
  }
  final pages = Directory('coverage/pages');
  if (pages.existsSync()) pages.deleteSync(recursive: true);
  pages.createSync(recursive: true);
  for (final MapEntry(key: layer, value: members) in byLayer.entries) {
    File(
      '${pages.path}/layer_$layer.html',
    ).writeAsStringSync(listPage(layer, members));
  }
  for (final MapEntry(key: folder, value: members) in folders.entries) {
    File(
      '${pages.path}/${folderPageName(folder)}',
    ).writeAsStringSync(listPage(folder, members));
  }
  for (final file in files) {
    File('${pages.path}/${file.pageName}').writeAsStringSync(filePage(file));
  }
  final sortedFolders = Map.fromEntries(
    folders.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  File(
    'coverage/index.html',
  ).writeAsStringSync(indexPage(total, layers, sortedFolders, files));
  stdout.writeln('Report: coverage/index.html');
}
