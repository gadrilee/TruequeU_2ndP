import 'package:flutter_test/flutter_test.dart';
import 'package:trueque_u/utilidades/etiquetas.dart';
import 'package:trueque_u/utilidades/formato_entrega.dart';
import 'package:trueque_u/utilidades/validadores.dart';

String fechaIso(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

void main() {
  group('etiquetas', () {
    test('traducen lo guardado a lo que se muestra', () {
      expect(etiquetasCategoria['electronica'], 'Electrónica');
      expect(etiquetasCondicion['usado'], 'Usado');
      expect(etiquetasDisponibilidad['reservado'], 'Reservado');
    });
  });

  group('fechaLegible', () {
    test('convierte ISO a dia/mes/anio', () {
      expect(fechaLegible('2026-03-07'), '07/03/2026');
    });

    test('si no tiene tres partes devuelve el mismo texto', () {
      expect(fechaLegible('2026/03'), '2026/03');
    });
  });

  group('fechaAIso', () {
    test('convierte dia/mes/anio a ISO con ceros', () {
      expect(fechaAIso('7/3/2026'), '2026-03-07');
      expect(fechaAIso(' 25/12/2026 '), '2026-12-25');
    });

    test('rechaza texto con otro formato', () {
      expect(fechaAIso('2026-03-07'), isNull);
      expect(fechaAIso(''), isNull);
    });

    test('rechaza fechas que no existen', () {
      expect(fechaAIso('31/02/2026'), isNull);
      expect(fechaAIso('10/13/2026'), isNull);
    });
  });

  group('fechaYaPaso', () {
    test('una fecha lejana en el pasado ya paso', () {
      expect(fechaYaPaso('2000-01-01'), true);
    });

    test('una fecha lejana en el futuro no ha pasado', () {
      expect(fechaYaPaso('2999-01-01'), false);
    });

    test('hoy no cuenta como pasado', () {
      expect(fechaYaPaso(fechaIso(DateTime.now())), false);
    });

    test('ayer ya paso', () {
      final ayer = DateTime.now().subtract(const Duration(days: 1));

      expect(fechaYaPaso(fechaIso(ayer)), true);
    });
  });

  group('horaAIso', () {
    test('agrega cero a la hora de un digito', () {
      expect(horaAIso('9:30'), '09:30');
      expect(horaAIso(' 23:59 '), '23:59');
    });

    test('rechaza horas fuera de rango o mal escritas', () {
      expect(horaAIso('24:00'), isNull);
      expect(horaAIso('10:60'), isNull);
      expect(horaAIso('1030'), isNull);
    });
  });

  group('resumenEntrega', () {
    test('junta fecha, hora y lugar', () {
      final texto = resumenEntrega({'fecha': '2026-03-07', 'hora': '10:30', 'lugar': 'Biblioteca'});

      expect(texto, '07/03/2026 a las 10:30 en Biblioteca');
    });
  });

  group('validarCorreo', () {
    test('pide el correo si esta vacio o es nulo', () {
      expect(validarCorreo(null), 'Escribe tu correo');
      expect(validarCorreo('   '), 'Escribe tu correo');
    });

    test('rechaza un correo mal escrito', () {
      expect(validarCorreo('ana@'), 'Correo no válido');
    });

    test('acepta un correo valido', () {
      expect(validarCorreo(' ana@correo.com '), isNull);
    });
  });

  group('validarTelefonoOpcional', () {
    test('acepta vacio o nulo', () {
      expect(validarTelefonoOpcional(null), isNull);
      expect(validarTelefonoOpcional(' '), isNull);
    });

    test('exige 8 digitos', () {
      expect(validarTelefonoOpcional('1234'), 'El teléfono debe tener 8 dígitos');
      expect(validarTelefonoOpcional('12345678'), isNull);
    });
  });

  group('validarContrasenaNueva', () {
    test('exige minimo 6 caracteres', () {
      expect(validarContrasenaNueva(null), 'Mínimo 6 caracteres');
      expect(validarContrasenaNueva('12345'), 'Mínimo 6 caracteres');
      expect(validarContrasenaNueva('123456'), isNull);
    });
  });
}
