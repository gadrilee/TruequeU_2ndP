const {
  validarPropuesta,
  puedeProponerEntrega,
  puedeAceptarEntrega,
  puedeContraproponerEntrega,
} = require("./reglasEntrega");

const ahora = new Date("2030-06-10T12:00:00Z");
const pedida = { id: 1, id_usuario: 1 };
const ofrecida = { id: 8, id_usuario: 3 };
const aceptada = { estado: "aceptada" };
const cuerpo = { fecha: "2030-06-15", hora: "15:00", lugar: "Biblioteca" };

describe("Regla: validar fecha, hora y lugar", () => {
  test("acepta datos correctos y limpia los espacios", () => {
    const resultado = validarPropuesta({ fecha: "2030-06-15", hora: "09:30", lugar: "  Biblioteca  " }, ahora);
    expect(resultado).toEqual({
      valido: true,
      datos: { fecha: "2030-06-15", hora: "09:30", lugar: "Biblioteca" },
    });
  });

  test.each([
    [{ ...cuerpo, fecha: "15/06/2030" }, "Escribe una fecha válida"],
    [{ ...cuerpo, fecha: "2030-02-31" }, "Escribe una fecha válida"],
    [{ ...cuerpo, fecha: "2030-06-01" }, "La fecha ya pasó, elige otra"],
    [{ ...cuerpo, hora: "25:00" }, "Escribe una hora válida"],
    [{ ...cuerpo, lugar: "   " }, "Escribe el lugar de la entrega"],
    [{ ...cuerpo, lugar: "a".repeat(121) }, "El lugar puede tener hasta 120 letras"],
  ])("rechaza %j", (datos, motivo) => {
    expect(validarPropuesta(datos, ahora)).toEqual({ valido: false, motivo });
  });

  test("la fecha de hoy y la de ayer todavía valen por la zona horaria", () => {
    expect(validarPropuesta({ ...cuerpo, fecha: "2030-06-10" }, ahora).valido).toBe(true);
    expect(validarPropuesta({ ...cuerpo, fecha: "2030-06-09" }, ahora).valido).toBe(true);
  });
});

describe("Regla: proponer la entrega", () => {
  const base = { oferta: aceptada, pedida, ofrecida, idUsuario: 1, cuerpo, ahora };

  test("cualquiera de las dos partes puede proponer", () => {
    expect(puedeProponerEntrega({ ...base, idUsuario: 1 }).permitido).toBe(true);
    expect(puedeProponerEntrega({ ...base, idUsuario: 3 }).permitido).toBe(true);
  });

  test("un tercero recibe 403", () => {
    const resultado = puedeProponerEntrega({ ...base, idUsuario: 2 });
    expect(resultado.codigo).toBe(403);
  });

  test("solo en un intercambio aceptado", () => {
    const resultado = puedeProponerEntrega({ ...base, oferta: { estado: "completada" } });
    expect(resultado.codigo).toBe(409);
  });

  test("con una propuesta pendiente no se puede hacer otra", () => {
    const resultado = puedeProponerEntrega({ ...base, pendiente: { id: 5 } });
    expect(resultado.codigo).toBe(409);
  });

  test("una reprogramación tiene que cambiar algo del acuerdo vigente", () => {
    const vigente = { fecha: "2030-06-15", hora: "15:00:00", lugar: "biblioteca" };
    const resultado = puedeProponerEntrega({ ...base, vigente });
    expect(resultado.codigo).toBe(409);
    expect(
      puedeProponerEntrega({ ...base, vigente, cuerpo: { ...cuerpo, hora: "16:00" } }).permitido,
    ).toBe(true);
  });

  test("datos incompletos dan 400", () => {
    const resultado = puedeProponerEntrega({ ...base, cuerpo: { fecha: "2030-06-15" } });
    expect(resultado.codigo).toBe(400);
  });
});

describe("Regla: responder una propuesta", () => {
  const propuesta = { id: 5, id_usuario: 1, estado: "pendiente", fecha: "2030-06-15", hora: "15:00:00", lugar: "Biblioteca" };
  const base = { oferta: aceptada, pedida, ofrecida, idUsuario: 3, propuesta };

  test("la otra parte puede aceptar", () => {
    expect(puedeAceptarEntrega(base).permitido).toBe(true);
  });

  test("quien propuso no puede responder su propia propuesta", () => {
    const resultado = puedeAceptarEntrega({ ...base, idUsuario: 1 });
    expect(resultado.codigo).toBe(403);
  });

  test("un tercero no puede responder", () => {
    expect(puedeAceptarEntrega({ ...base, idUsuario: 2 }).codigo).toBe(403);
  });

  test("una propuesta ya respondida da 409", () => {
    const resultado = puedeAceptarEntrega({ ...base, propuesta: { ...propuesta, estado: "contrapuesta" } });
    expect(resultado.codigo).toBe(409);
  });

  test("la contrapropuesta tiene que cambiar algo", () => {
    const igual = puedeContraproponerEntrega({ ...base, cuerpo, ahora });
    expect(igual.codigo).toBe(409);

    const distinta = puedeContraproponerEntrega({ ...base, cuerpo: { ...cuerpo, lugar: "Cafetería" }, ahora });
    expect(distinta.permitido).toBe(true);
    expect(distinta.datos.lugar).toBe("Cafetería");
  });

  test("no se responde cuando el intercambio ya terminó", () => {
    const resultado = puedeAceptarEntrega({ ...base, oferta: { estado: "anulada" } });
    expect(resultado.codigo).toBe(409);
  });
});
