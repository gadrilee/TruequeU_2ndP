const {
  estaAcordado,
  estaIntercambiado,
  parteDelIntercambio,
  puedeCrearOferta,
  puedeCompletarIntercambio,
} = require("./reglasObjeto");

describe("Estados de una publicacion", () => {
  test("estaAcordado solo es verdadero para una publicacion acordada", () => {
    expect(estaAcordado({ estado_publicacion: "acordado" })).toBe(true);
    expect(estaAcordado({ estado_publicacion: "disponible" })).toBe(false);
  });

  test("estaIntercambiado solo es verdadero para una publicacion intercambiada", () => {
    expect(estaIntercambiado({ estado_publicacion: "intercambiado" })).toBe(true);
    expect(estaIntercambiado({ estado_publicacion: "reservado" })).toBe(false);
  });
});

describe("Parte de un intercambio", () => {
  const pedida = { id_usuario: 1 };
  const ofrecida = { id_usuario: 3 };

  test("el dueno de la pedida es la parte pedida", () => {
    expect(parteDelIntercambio({}, pedida, ofrecida, 1)).toBe("pedida");
  });

  test("el dueno de la ofrecida es la parte ofrecida", () => {
    expect(parteDelIntercambio({}, pedida, ofrecida, 3)).toBe("ofrecida");
  });

  test("un tercero no es parte", () => {
    expect(parteDelIntercambio({}, pedida, ofrecida, 2)).toBeNull();
  });
});

describe("Regla: completar un intercambio ya completado", () => {
  test("una publicacion intercambiada da 409", () => {
    const publicacion = { id_usuario: 1, id_usuario_reserva: 2, estado_publicacion: "intercambiado" };

    const resultado = puedeCompletarIntercambio(publicacion, 1);

    expect(resultado.codigo).toBe(409);
    expect(resultado.motivo).toBe("Este intercambio ya fue completado");
  });

  test("una publicacion no reservada da 409", () => {
    const publicacion = { id_usuario: 1, id_usuario_reserva: null, estado_publicacion: "disponible" };

    expect(puedeCompletarIntercambio(publicacion, 1).codigo).toBe(409);
  });
});

describe("Regla: crear una oferta", () => {
  const pedida = { id: 1, id_usuario: 1, estado_publicacion: "disponible" };
  const ofrecida = { id: 8, id_usuario: 3, estado_publicacion: "disponible" };
  const base = { pedida, ofrecida, idUsuario: 3, ofrecidaYaPrometida: false };

  test("una oferta correcta es permitida", () => {
    expect(puedeCrearOferta(base)).toEqual({ permitido: true });
  });

  test.each([
    ["sin publicacion pedida", { pedida: null }, 404, "La publicación que quieres no existe"],
    ["sin objeto ofrecido", { ofrecida: null }, 404, "El objeto que ofreces no existe"],
    ["mismo objeto", { ofrecida: { ...pedida } }, 400, "Tienes que ofrecer un objeto distinto del que quieres"],
    ["publicacion propia", { idUsuario: 1 }, 403, "No puedes hacer una oferta por tu propia publicación"],
    ["objeto de otra persona", { idUsuario: 5 }, 403, "Solo puedes ofrecer un objeto de tus publicaciones"],
    [
      "pedida no disponible",
      { pedida: { ...pedida, estado_publicacion: "reservado" } },
      409,
      "Solo puedes ofertar por una publicación disponible",
    ],
    [
      "ofrecida no disponible",
      { ofrecida: { ...ofrecida, estado_publicacion: "reservado" } },
      409,
      "Solo puedes ofrecer un objeto tuyo que esté disponible",
    ],
    [
      "ofrecida ya prometida",
      { ofrecidaYaPrometida: true },
      409,
      "Ese objeto ya está en otra oferta pendiente. Cancélala si quieres usarlo en otra",
    ],
  ])("%s", (nombre, cambios, codigo, motivo) => {
    expect(puedeCrearOferta({ ...base, ...cambios })).toEqual({ permitido: false, codigo, motivo });
  });
});
