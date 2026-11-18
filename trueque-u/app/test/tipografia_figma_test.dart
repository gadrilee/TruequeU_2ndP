import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/tema.dart';
import 'package:trueque_u/widgets/encabezado_acceso.dart';

const tamanoPorDefecto = 14.0;
const escalaEtiquetaFlotante = 0.75;

Map<String, dynamic> seccion(Map<String, dynamic> json, String nombre) =>
    json[nombre] as Map<String, dynamic>;

class Medidas {
  Medidas(this.tamano, this.altura, this.espaciado, this.peso);

  final double tamano;
  final double? altura;
  final double? espaciado;
  final int peso;

  factory Medidas.deEstilo(TextStyle estilo) => Medidas(
        estilo.fontSize ?? tamanoPorDefecto,
        estilo.height,
        estilo.letterSpacing,
        (estilo.fontWeight ?? FontWeight.w400).value,
      );

  @override
  String toString() => '$tamano/$altura/$espaciado/$peso';

  @override
  bool operator ==(Object otro) =>
      otro is Medidas &&
      otro.tamano == tamano &&
      otro.altura == altura &&
      otro.espaciado == espaciado &&
      otro.peso == peso;

  @override
  int get hashCode => Object.hash(tamano, altura, espaciado, peso);
}

Medidas deJson(Map<String, dynamic> json, Map<String, double> tipos) {
  final tamano = json['fontSize'];
  return Medidas(
    tamano is String ? tipos[tamano.split('/')[1]]! : (tamano as num).toDouble(),
    (json['height'] as num?)?.toDouble(),
    (json['letterSpacing'] as num?)?.toDouble(),
    json['fontWeight'] as int,
  );
}

final tipos = <String, double>{
  't11': Tipos.t11,
  't12': Tipos.t12,
  't13': Tipos.t13,
  't14': Tipos.t14,
  't16': Tipos.t16,
  't17': Tipos.t17,
  't18': Tipos.t18,
  't26': Tipos.t26,
};

final efectivos = <String, TextStyle>{
  'titulo': TextosTruequeU.titulo,
  'subtitulo': TextosTruequeU.subtitulo,
  'tituloTarjeta': TextosTruequeU.tituloTarjeta,
  'tituloItem': TextosTruequeU.tituloItem,
  'cuerpo': TextosTruequeU.cuerpo,
  'detalle': TextosTruequeU.detalle,
  'etiqueta': TextosTruequeU.etiqueta,
  'ayuda': TextosTruequeU.ayuda,
  'chip': TextosTruequeU.chip,
  'chipDestacado': TextosTruequeU.chipDestacado,
  'pie': TextosTruequeU.pie,
};

Future<void> montar(WidgetTester t, Widget cuerpo, {PreferredSizeWidget? barra, Widget? navegacion}) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(
    MaterialApp(
      theme: TemaTruequeU.claro(),
      home: Scaffold(
        appBar: barra,
        bottomNavigationBar: navegacion,
        body: Center(child: cuerpo),
      ),
    ),
  );
  await t.pumpAndSettle();
}

TextStyle estiloDe(WidgetTester t, String texto) {
  final parrafo = t.widget<RichText>(
    find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == texto).first,
  );
  return parrafo.text.style!;
}

TextStyle conTema(BuildContext c, TextStyle? Function(TextTheme) elegir, FontWeight peso) =>
    elegir(Theme.of(c).textTheme)!.copyWith(fontWeight: peso);

void main() {
  final json = jsonDecode(
    File('../../design/figma-plugin/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final roles = seccion(json, 'TextTheme');
  final derivados = seccion(json, 'TextoDerivado');
  final contextos = seccion(json, 'Contextos');

  Medidas medidasDe(String referencia) {
    final partes = referencia.split('/');
    final origen = seccion(json, partes[0]);
    expect(
      ['TextTheme', 'TextosTruequeU', 'TextoDerivado'].contains(partes[0]),
      true,
      reason: referencia,
    );
    return deJson(origen[partes[1]] as Map<String, dynamic>, tipos);
  }

  testWidgets('TextTheme resuelto del ThemeData coincide con tokens.json', (t) async {
    late ThemeData tema;
    await montar(t, Builder(builder: (c) {
      tema = Theme.of(c);
      return const SizedBox();
    }));
    final texto = tema.textTheme;
    final reales = <String, TextStyle?>{
      'displayLarge': texto.displayLarge,
      'displayMedium': texto.displayMedium,
      'displaySmall': texto.displaySmall,
      'headlineLarge': texto.headlineLarge,
      'headlineMedium': texto.headlineMedium,
      'headlineSmall': texto.headlineSmall,
      'titleLarge': texto.titleLarge,
      'titleMedium': texto.titleMedium,
      'titleSmall': texto.titleSmall,
      'bodyLarge': texto.bodyLarge,
      'bodyMedium': texto.bodyMedium,
      'bodySmall': texto.bodySmall,
      'labelLarge': texto.labelLarge,
      'labelMedium': texto.labelMedium,
      'labelSmall': texto.labelSmall,
    };

    expect(roles.keys.toSet(), reales.keys.toSet());
    reales.forEach((rol, estilo) {
      expect(estilo!.fontFamily, 'Roboto', reason: rol);
      expect(deJson(roles[rol] as Map<String, dynamic>, tipos), Medidas.deEstilo(estilo), reason: rol);
    });
  });

  testWidgets('TextosTruequeU efectivo es DefaultTextStyle del cuerpo mezclado con el estilo', (t) async {
    final tokens = seccion(json, 'TextosTruequeU');
    late TextStyle base;
    await montar(t, Builder(builder: (c) {
      base = DefaultTextStyle.of(c).style;
      return const SizedBox();
    }));

    expect(Medidas.deEstilo(base), deJson(roles['bodyMedium'] as Map<String, dynamic>, tipos));
    expect(tokens.keys.toSet(), efectivos.keys.toSet());
    efectivos.forEach((nombre, estilo) {
      final efectivo = base.merge(estilo);
      expect(deJson(tokens[nombre] as Map<String, dynamic>, tipos), Medidas.deEstilo(efectivo), reason: nombre);
    });
  });

  final lecturas = <String, Future<Medidas> Function(WidgetTester)>{
    'Scaffold.texto': (t) async {
      await montar(t, const Text('x'));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'FilledButton': (t) async {
      await montar(t, FilledButton(onPressed: () {}, child: const Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'FilledButton.tonal': (t) async {
      await montar(t, FilledButton.tonal(onPressed: () {}, child: const Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'OutlinedButton': (t) async {
      await montar(t, OutlinedButton(onPressed: () {}, child: const Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextButton': (t) async {
      await montar(t, TextButton(onPressed: () {}, child: const Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextButton.negrita': (t) async {
      await montar(
        t,
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {},
          child: const Text('x'),
        ),
      );
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'FloatingActionButton.extended': (t) async {
      await montar(t, FloatingActionButton.extended(onPressed: () {}, label: const Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'AppBar.titulo': (t) async {
      await montar(t, const SizedBox(), barra: AppBar(title: const Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextField.entrada': (t) async {
      await montar(t, TextFormField(initialValue: 'valor'));
      return Medidas.deEstilo(t.widget<EditableText>(find.byType(EditableText)).style);
    },
    'TextField.hint': (t) async {
      await montar(t, const TextField(decoration: InputDecoration(hintText: 'x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextField.etiqueta': (t) async {
      await montar(t, TextFormField(decoration: const InputDecoration(labelText: 'x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextField.etiquetaFlotante': (t) async {
      await montar(t, TextFormField(initialValue: 'valor', decoration: const InputDecoration(labelText: 'x')));
      final e = estiloDe(t, 'x');
      return Medidas(e.fontSize! * escalaEtiquetaFlotante, e.height, e.letterSpacing! * escalaEtiquetaFlotante, e.fontWeight!.value);
    },
    'TextField.ayuda': (t) async {
      await montar(t, TextFormField(decoration: const InputDecoration(labelText: 'e', helperText: 'x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextField.error': (t) async {
      await montar(
        t,
        TextFormField(
          autovalidateMode: AutovalidateMode.always,
          validator: (_) => 'x',
          decoration: const InputDecoration(labelText: 'e'),
        ),
      );
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'TextField.contador': (t) async {
      await montar(t, TextFormField(maxLength: 200, decoration: const InputDecoration(labelText: 'e')));
      return Medidas.deEstilo(estiloDe(t, '0/200'));
    },
    'DropdownButtonFormField.valor': (t) async {
      await montar(
        t,
        DropdownButtonFormField<String>(
          initialValue: 'a',
          decoration: const InputDecoration(labelText: 'e'),
          items: const [DropdownMenuItem(value: 'a', child: Text('x'))],
          onChanged: (_) {},
        ),
      );
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'ListTile.titulo': (t) async {
      await montar(t, const Card(child: ListTile(title: Text('x'), subtitle: Text('y'))));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'ListTile.subtitulo': (t) async {
      await montar(t, const Card(child: ListTile(title: Text('x'), subtitle: Text('y'))));
      return Medidas.deEstilo(estiloDe(t, 'y'));
    },
    'RadioListTile.titulo': (t) async {
      await montar(
        t,
        RadioGroup<int>(
          groupValue: 0,
          onChanged: (_) {},
          child: const RadioListTile<int>(value: 0, title: Text('x'), subtitle: Text('y')),
        ),
      );
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'RadioListTile.subtitulo': (t) async {
      await montar(
        t,
        RadioGroup<int>(
          groupValue: 0,
          onChanged: (_) {},
          child: const RadioListTile<int>(value: 0, title: Text('x'), subtitle: Text('y')),
        ),
      );
      return Medidas.deEstilo(estiloDe(t, 'y'));
    },
    'AlertDialog.titulo': (t) async {
      await montar(t, const AlertDialog(title: Text('x'), content: Text('y')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'AlertDialog.contenido': (t) async {
      await montar(t, const AlertDialog(title: Text('x'), content: Text('y')));
      return Medidas.deEstilo(estiloDe(t, 'y'));
    },
    'NavigationBar.etiqueta': (t) async {
      await montar(
        t,
        const SizedBox(),
        navegacion: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'x'),
            NavigationDestination(icon: Icon(Icons.person), label: 'y'),
          ],
        ),
      );
      final elegido = Medidas.deEstilo(estiloDe(t, 'x'));
      expect(Medidas.deEstilo(estiloDe(t, 'y')), elegido);
      return elegido;
    },
    'SnackBar': (t) async {
      await montar(
        t,
        Builder(
          builder: (c) => TextButton(
            onPressed: () => ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('x'))),
            child: const Text('abrir'),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Chip': (t) async {
      await montar(t, const Chip(label: Text('x')));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'InputChip': (t) async {
      await montar(t, InputChip(label: const Text('x'), onDeleted: () {}));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'SegmentedButton': (t) async {
      await montar(
        t,
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('x')),
            ButtonSegment(value: 1, label: Text('y')),
          ],
          selected: const {0},
          onSelectionChanged: (_) {},
        ),
      );
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'CircleAvatar.grande': (t) async {
      await montar(t, const CircleAvatar(radius: 36, child: Text('x', style: TextosTruequeU.titulo)));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'CircleAvatar.chico': (t) async {
      await montar(t, const CircleAvatar(radius: 11, child: Text('x', style: TextosTruequeU.ayuda)));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'EncabezadoAcceso.titulo': (t) async {
      await montar(t, const EncabezadoAcceso(titulo: 'x', subtitulo: 'y'));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'EncabezadoAcceso.subtitulo': (t) async {
      await montar(t, const EncabezadoAcceso(titulo: 'x', subtitulo: 'y'));
      return Medidas.deEstilo(estiloDe(t, 'y'));
    },
    'Text.negrita': (t) async {
      await montar(t, const Text('x', style: TextStyle(fontWeight: FontWeight.bold)));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Text.semibold': (t) async {
      await montar(t, const Text('x', style: TextStyle(fontWeight: FontWeight.w600)));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Text.chipSemibold': (t) async {
      await montar(t, const Text('x', style: TextStyle(fontSize: Tipos.t11, fontWeight: FontWeight.w600)));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Text.autorPropio': (t) async {
      await montar(t, const Text('x', style: TextStyle(fontSize: Tipos.t12, fontWeight: FontWeight.bold)));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Text.headlineSmallNegrita': (t) async {
      await montar(t, Builder(builder: (c) => Text('x', style: conTema(c, (m) => m.headlineSmall, FontWeight.bold))));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Text.titleLargeNegrita': (t) async {
      await montar(t, Builder(builder: (c) => Text('x', style: conTema(c, (m) => m.titleLarge, FontWeight.bold))));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
    'Text.titleMediumNegrita': (t) async {
      await montar(t, Builder(builder: (c) => Text('x', style: conTema(c, (m) => m.titleMedium, FontWeight.bold))));
      return Medidas.deEstilo(estiloDe(t, 'x'));
    },
  };

  test('los contextos de tokens.json son exactamente los verificados', () {
    expect(contextos.keys.toSet(), lecturas.keys.toSet());
  });

  test('cada estilo derivado lo usa al menos un contexto y toda referencia existe', () {
    final usados = <String>{};
    for (final referencia in contextos.values.cast<String>()) {
      medidasDe(referencia);
      if (referencia.startsWith('TextoDerivado/')) usados.add(referencia.split('/')[1]);
    }
    expect(derivados.keys.toSet(), usados);
  });

  for (final entrada in lecturas.entries) {
    testWidgets('contexto ${entrada.key} usa el estilo de tokens.json', (t) async {
      final real = await entrada.value(t);
      final esperado = medidasDe(contextos[entrada.key] as String);
      expect(real, esperado, reason: '${entrada.key} -> ${contextos[entrada.key]}');
    });
  }
}
