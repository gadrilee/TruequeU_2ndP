const { validarCalificacion, puedeCalificar } = require("./reglasCalificacion");

const pedida = { id: 1, id_usuario: 1 };
const ofrecida = { id: 8, id_usuario: 3 };
const completada = { estado: "completada" };
const base = { oferta: completada, pedida, ofrecida, idUsuario: 1, yaCalifico: false, cuerpo: { puntaje: 5 } };

describe("Regla: validar la calificación", () => {
  test.each([1, 2, 3, 4, 5])("acepta el puntaje %i", (puntaje) => {
    expect(validarCalificacion({ puntaje }).valido).toBe(true);
  });

  test.each([[0], [6], [-1], [3.5], ["4"], [null], [undefined]])("rechaza el puntaje %p", (puntaje) => {
    expect(validarCalificacion({ puntaje })).toEqual({
      valido: false,
      motivo: "El puntaje tiene que ser un número de 1 a 5",
    });
  });

  test("el comentario es opcional y se limpia", () => {
    expect(validarCalificacion({ puntaje: 4 }).datos.comentario).toBeNull();
    expect(validarCalificacion({ puntaje: 4, comentario: "   " }).datos.comentario).toBeNull();
    expect(validarCalificacion({ puntaje: 4, comentario: "  Muy puntual  " }).datos.comentario).toBe("Muy puntual");
  });

  test("rechaza un comentario que no es texto o es muy largo", () => {
    expect(validarCalificacion({ puntaje: 4, comentario: 7 }).motivo).toBe("El comentario tiene que ser texto");
    expect(validarCalificacion({ puntaje: 4, comentario: "a".repeat(201) }).motivo).toBe(
      "El comentario puede tener hasta 200 letras",
    );
    expect(validarCalificacion({ puntaje: 4, comentario: "a".repeat(200) }).valido).toBe(true);
  });
});

describe("Regla: calificar un intercambio", () => {
  test("cada parte califica a la otra", () => {
    expect(puedeCalificar({ ...base, idUsuario: 1 })).toMatchObject({ permitido: true, idCalificado: 3 });
    expect(puedeCalificar({ ...base, idUsuario: 3 })).toMatchObject({ permitido: true, idCalificado: 1 });
  });

  test("devuelve los datos ya limpios", () => {
    const resultado = puedeCalificar({ ...base, cuerpo: { puntaje: 4, comentario: " Bien " } });
    expect(resultado.datos).toEqual({ puntaje: 4, comentario: "Bien" });
  });

  test("un tercero recibe 403", () => {
    const resultado = puedeCalificar({ ...base, idUsuario: 2 });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(403);
  });

  test("un intercambio cancelado recibe 409", () => {
    const resultado = puedeCalificar({ ...base, oferta: { estado: "anulada" } });
    expect(resultado.codigo).toBe(409);
    expect(resultado.motivo).toBe("Un intercambio cancelado no se puede calificar");
  });

  test.each(["pendiente", "aceptada", "rechazada", "cancelada", "contraofertada"])(
    "un intercambio %s todavía no se califica",
    (estado) => {
      const resultado = puedeCalificar({ ...base, oferta: { estado } });
      expect(resultado.codigo).toBe(409);
      expect(resultado.motivo).toBe("Solo se puede calificar un intercambio completado");
    },
  );

  test("una segunda calificación recibe 409", () => {
    const resultado = puedeCalificar({ ...base, yaCalifico: true });
    expect(resultado.codigo).toBe(409);
    expect(resultado.motivo).toBe("Ya calificaste este intercambio");
  });

  test("un puntaje inválido recibe 400", () => {
    const resultado = puedeCalificar({ ...base, cuerpo: { puntaje: 9 } });
    expect(resultado.codigo).toBe(400);
  });

  test("primero se revisa quién es y el estado, y después los datos", () => {
    expect(puedeCalificar({ ...base, idUsuario: 2, cuerpo: {} }).codigo).toBe(403);
    expect(puedeCalificar({ ...base, oferta: { estado: "anulada" }, cuerpo: {} }).codigo).toBe(409);
  });
});
