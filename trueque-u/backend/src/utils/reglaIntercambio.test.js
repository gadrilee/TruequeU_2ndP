const {
  puedeConfirmarEntrega,
  puedeCancelarIntercambio,
} = require("./reglasObjeto");

const pedida = { id: 1, id_usuario: 1 };
const ofrecida = { id: 8, id_usuario: 3 };
const aceptada = { estado: "aceptada", confirma_pedida: false, confirma_ofrecida: false };

describe("Regla: confirmar la entrega", () => {
  test("cada parte puede confirmar su entrega", () => {
    expect(puedeConfirmarEntrega({ oferta: aceptada, pedida, ofrecida, idUsuario: 1 })).toEqual({
      permitido: true,
      parte: "pedida",
    });
    expect(puedeConfirmarEntrega({ oferta: aceptada, pedida, ofrecida, idUsuario: 3 })).toEqual({
      permitido: true,
      parte: "ofrecida",
    });
  });

  test("no se confirma dos veces", () => {
    const oferta = { ...aceptada, confirma_pedida: true };
    const resultado = puedeConfirmarEntrega({ oferta, pedida, ofrecida, idUsuario: 1 });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(409);
  });

  test("un tercero no puede confirmar", () => {
    const resultado = puedeConfirmarEntrega({ oferta: aceptada, pedida, ofrecida, idUsuario: 2 });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(403);
  });

  test("solo se confirma un intercambio aceptado", () => {
    const oferta = { ...aceptada, estado: "completada" };
    const resultado = puedeConfirmarEntrega({ oferta, pedida, ofrecida, idUsuario: 1 });
    expect(resultado.permitido).toBe(false);
    expect(resultado.codigo).toBe(409);
  });
});

describe("Regla: cancelar un intercambio acordado", () => {
  test("cualquiera de las dos partes cancela con motivo", () => {
    const base = { oferta: aceptada, pedida, ofrecida, motivo: "No pude ir" };
    expect(puedeCancelarIntercambio({ ...base, idUsuario: 1 }).permitido).toBe(true);
    expect(puedeCancelarIntercambio({ ...base, idUsuario: 3 }).permitido).toBe(true);
  });

  test("sin motivo no se cancela", () => {
    const base = { oferta: aceptada, pedida, ofrecida, idUsuario: 1 };
    expect(puedeCancelarIntercambio({ ...base, motivo: "   " }).codigo).toBe(400);
    expect(puedeCancelarIntercambio({ ...base }).codigo).toBe(400);
  });

  test("un tercero no puede cancelar", () => {
    const resultado = puedeCancelarIntercambio({
      oferta: aceptada,
      pedida,
      ofrecida,
      idUsuario: 2,
      motivo: "Quiero cancelar",
    });
    expect(resultado.codigo).toBe(403);
  });

  test("un intercambio completado ya no se cancela", () => {
    const resultado = puedeCancelarIntercambio({
      oferta: { ...aceptada, estado: "completada" },
      pedida,
      ofrecida,
      idUsuario: 1,
      motivo: "Tarde",
    });
    expect(resultado.codigo).toBe(409);
  });
});
