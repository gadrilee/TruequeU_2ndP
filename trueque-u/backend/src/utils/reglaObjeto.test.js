const {
  estaReservado,
  puedeCompletarIntercambio,
  puedeCrearOferta,
} = require("./reglasObjeto");

describe("Restricción: publicación reservada", () => {
  test("una publicación reservada está bloqueada", () => {
    const publicacion = { estado_publicacion: "reservado" };
    const resultado = estaReservado(publicacion);
    expect(resultado).toBe(true);
  });

  test("una publicación disponible no está bloqueada", () => {
    const publicacion = { estado_publicacion: "disponible" };
    const resultado = estaReservado(publicacion);
    expect(resultado).toBe(false);
  });
});

describe("Regla: completar un intercambio", () => {
  // Dueño: usuario 1. Quien reservó: usuario 2. Un tercero: usuario 3
  const reservada = {
    id_usuario: 1,
    id_usuario_reserva: 2,
    estado_publicacion: "reservado",
  };

  // CASO PERMITIDO: el dueño completa una publicación reservada
  test("el dueño puede completar un objeto reservado", () => {
    const resultado = puedeCompletarIntercambio(reservada, 1);
    expect(resultado.permitido).toBe(true);
  });

  // CASO PERMITIDO: quien reservó también puede completarlo
  test("quien reservó puede completar el intercambio", () => {
    const resultado = puedeCompletarIntercambio(reservada, 2);
    expect(resultado.permitido).toBe(true);
  });

  // CASO RECHAZADO: un objeto disponible no se puede completar
  test("un objeto disponible no se puede completar", () => {
    const disponible = { ...reservada, id_usuario_reserva: null, estado_publicacion: "disponible" };
    const resultado = puedeCompletarIntercambio(disponible, 1);
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(409);
  });

  // CASO RECHAZADO: un intercambio completado no se completa otra vez
  test("un intercambio ya completado no se puede completar otra vez", () => {
    const completada = { ...reservada, estado_publicacion: "intercambiado" };
    const resultado = puedeCompletarIntercambio(completada, 1);
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(409);
  });

  // CASO RECHAZADO: alguien que no es el dueño ni quien reservó
  test("un tercero no puede completar el intercambio", () => {
    const resultado = puedeCompletarIntercambio(reservada, 3);
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(403);
  });
});

describe("Regla: crear una oferta de trueque", () => {
  const pedida = { id: 1, id_usuario: 1, estado_publicacion: "disponible" };
  const ofrecida = { id: 8, id_usuario: 3, estado_publicacion: "disponible" };

  test("puedo ofrecer un objeto mío por uno ajeno disponible", () => {
    const resultado = puedeCrearOferta({
      pedida,
      ofrecida,
      idUsuario: 3,
      ofrecidaYaPrometida: false,
    });
    expect(resultado.permitido).toBe(true);
  });

  test("no puedo ofertar por mi propia publicación", () => {
    const resultado = puedeCrearOferta({
      pedida,
      ofrecida: { id: 3, id_usuario: 1, estado_publicacion: "disponible" },
      idUsuario: 1,
      ofrecidaYaPrometida: false,
    });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(403);
  });

  test("no puedo ofrecer un objeto que no es mío", () => {
    const resultado = puedeCrearOferta({
      pedida,
      ofrecida,
      idUsuario: 2,
      ofrecidaYaPrometida: false,
    });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(403);
  });

  test("no puedo ofrecer un objeto que ya está en otra oferta pendiente", () => {
    const resultado = puedeCrearOferta({
      pedida,
      ofrecida,
      idUsuario: 3,
      ofrecidaYaPrometida: true,
    });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(409);
  });
});
