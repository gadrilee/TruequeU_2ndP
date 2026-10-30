const { idReceptor, puedeContraofertar } = require("./reglasObjeto");

describe("Regla: contraoferta", () => {
  const pedida = { id: 1, id_usuario: 1, estado_publicacion: "disponible" };
  const mouse = { id: 8, id_usuario: 3, estado_publicacion: "disponible" };
  const mandil = { id: 7, id_usuario: 3, estado_publicacion: "disponible" };
  const ofertaDeCarlos = { id: 1, id_usuario: 3, estado: "pendiente" };

  function datos(cambios = {}) {
    return {
      oferta: ofertaDeCarlos,
      pedida,
      ofrecidaActual: mouse,
      nueva: mandil,
      idUsuario: 1,
      nuevaYaPrometida: false,
      ...cambios,
    };
  }

  test("recibe la oferta la persona que no la escribió", () => {
    expect(idReceptor(ofertaDeCarlos, pedida, mouse)).toBe(1);
    const contraoferta = { id: 2, id_usuario: 1, estado: "pendiente" };
    expect(idReceptor(contraoferta, pedida, mandil)).toBe(3);
  });

  test("la dueña puede responder con otro objeto de Carlos", () => {
    expect(puedeContraofertar(datos()).permitido).toBe(true);
  });

  test("quien escribió la oferta no puede contraofertarla", () => {
    const resultado = puedeContraofertar(datos({ idUsuario: 3 }));
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(403);
  });

  test("una tercera persona no puede contraofertar", () => {
    const resultado = puedeContraofertar(datos({ idUsuario: 2 }));
    expect(resultado.codigo).toBe(403);
  });

  test("una negociación cerrada no se puede contraofertar", () => {
    const cerrada = { ...ofertaDeCarlos, estado: "aceptada" };
    const resultado = puedeContraofertar(datos({ oferta: cerrada }));
    expect(resultado.codigo).toBe(409);
    expect(resultado.motivo).toContain("cerrada");
  });

  test("el objeto nuevo tiene que existir", () => {
    const resultado = puedeContraofertar(datos({ nueva: null }));
    expect(resultado.codigo).toBe(404);
  });

  test("el objeto nuevo tiene que ser de quien ofrece", () => {
    const ajeno = { id: 3, id_usuario: 1, estado_publicacion: "disponible" };
    const resultado = puedeContraofertar(datos({ nueva: ajeno }));
    expect(resultado.codigo).toBe(403);
  });

  test("la contraoferta tiene que cambiar el objeto ofrecido", () => {
    const resultado = puedeContraofertar(datos({ nueva: mouse }));
    expect(resultado.codigo).toBe(400);
  });

  test("el objeto nuevo tiene que estar disponible", () => {
    const reservado = { ...mandil, estado_publicacion: "reservado" };
    const resultado = puedeContraofertar(datos({ nueva: reservado }));
    expect(resultado.codigo).toBe(409);
  });

  test("el objeto nuevo no puede estar en otra oferta pendiente", () => {
    const resultado = puedeContraofertar(datos({ nuevaYaPrometida: true }));
    expect(resultado.codigo).toBe(409);
  });

  test("no se contraoferta si lo pedido ya no está disponible", () => {
    const intercambiada = { ...pedida, estado_publicacion: "intercambiado" };
    const resultado = puedeContraofertar(datos({ pedida: intercambiada }));
    expect(resultado.codigo).toBe(409);
  });
});
