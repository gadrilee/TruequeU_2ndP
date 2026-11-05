jest.mock("../database/sequelize", () => ({
  sequelize: {
    literal: jest.fn((texto) => texto),
    transaction: jest.fn((funcion) => funcion({ LOCK: { UPDATE: "UPDATE" } })),
  },
  models: {
    usuarios: {},
    historial: { bulkCreate: jest.fn() },
    publicaciones: { findByPk: jest.fn() },
    ofertas: { findByPk: jest.fn() },
  },
}));

const { models } = require("../database/sequelize");
const { putOfertaEntrega, putOfertaAnulada } = require("./ofertas.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function conUpdate(objeto) {
  objeto.update = jest.fn(async (cambios) => Object.assign(objeto, cambios));
  objeto.reload = jest.fn().mockResolvedValue(objeto);
  return objeto;
}

let oferta;
let libro;
let mouse;

beforeEach(() => {
  jest.clearAllMocks();
  oferta = conUpdate({
    id: 1,
    id_publicacion_pedida: 1,
    id_publicacion_ofrecida: 8,
    id_usuario: 3,
    estado: "aceptada",
    confirma_pedida: false,
    confirma_ofrecida: false,
  });
  libro = conUpdate({ id: 1, id_usuario: 1, titulo: "Calculo I", categoria: "libros", estado_publicacion: "acordado" });
  mouse = conUpdate({ id: 8, id_usuario: 3, titulo: "Mouse", categoria: "electronica", estado_publicacion: "acordado" });
  models.ofertas.findByPk.mockResolvedValue(oferta);
  models.publicaciones.findByPk.mockImplementation(async (id) => ({ 1: libro, 8: mouse })[id] || null);
});

async function pedir(controlador, idUsuario, body = {}) {
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, params: { id: "1" }, body }, res);
  return res;
}

describe("Confirmar la entrega", () => {
  test("la primera confirmación no completa el intercambio", async () => {
    const res = await pedir(putOfertaEntrega, 1);

    expect(oferta.confirma_pedida).toBe(true);
    expect(oferta.estado).toBe("aceptada");
    expect(libro.estado_publicacion).toBe("acordado");
    expect(models.historial.bulkCreate).not.toHaveBeenCalled();
    expect(res.json.mock.calls[0][0].mensaje).toBe("Confirmaste tu entrega. Falta que la otra persona confirme");
  });

  test("la segunda confirmación completa el intercambio", async () => {
    oferta.confirma_pedida = true;
    const res = await pedir(putOfertaEntrega, 3);

    expect(oferta.estado).toBe("completada");
    expect(libro.estado_publicacion).toBe("intercambiado");
    expect(mouse.estado_publicacion).toBe("intercambiado");
    expect(models.historial.bulkCreate).toHaveBeenCalledTimes(1);
    expect(models.historial.bulkCreate.mock.calls[0][0]).toHaveLength(2);
    expect(res.json.mock.calls[0][0].mensaje).toBe("Intercambio completado. Las dos partes confirmaron la entrega");
  });

  test("la misma persona no confirma dos veces", async () => {
    oferta.confirma_pedida = true;
    const res = await pedir(putOfertaEntrega, 1);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(oferta.estado).toBe("aceptada");
  });

  test("un tercero no puede confirmar", async () => {
    const res = await pedir(putOfertaEntrega, 2);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(oferta.confirma_pedida).toBe(false);
  });
});

describe("Cancelar un intercambio acordado", () => {
  test("libera las dos publicaciones y guarda el motivo", async () => {
    const res = await pedir(putOfertaAnulada, 3, { motivo: "  No puedo ir  " });

    expect(oferta.estado).toBe("anulada");
    expect(oferta.motivo_cancelacion).toBe("No puedo ir");
    expect(oferta.id_usuario_cancela).toBe(3);
    expect(libro.estado_publicacion).toBe("disponible");
    expect(mouse.estado_publicacion).toBe("disponible");
    expect(models.historial.bulkCreate).not.toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  test("sin motivo responde 400 y no cambia nada", async () => {
    const res = await pedir(putOfertaAnulada, 1, { motivo: "" });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(oferta.estado).toBe("aceptada");
    expect(libro.estado_publicacion).toBe("acordado");
  });

  test("un intercambio completado no se cancela", async () => {
    oferta.estado = "completada";
    const res = await pedir(putOfertaAnulada, 1, { motivo: "Tarde" });

    expect(res.status).toHaveBeenCalledWith(409);
  });
});
