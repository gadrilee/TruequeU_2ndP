const { Op } = require("sequelize");

jest.mock("../database/sequelize", () => ({
  sequelize: {
    literal: jest.fn((texto) => texto),
    transaction: jest.fn((funcion) => funcion({ LOCK: { UPDATE: "UPDATE" } })),
  },
  models: {
    usuarios: {},
    historial: { bulkCreate: jest.fn() },
    publicaciones: { findByPk: jest.fn() },
    ofertas: {
      findByPk: jest.fn(),
      findAll: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  },
}));

const { models } = require("../database/sequelize");
const {
  postOferta,
  getOfertasRecibidas,
  getOfertasEnviadas,
  putOfertaAceptada,
  putOfertaRechazada,
  putOfertaCancelada,
  putOfertaEntrega,
  putOfertaAnulada,
  postContraoferta,
  getHistorialOferta,
} = require("./ofertas.controlador");

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

async function pedir(controlador, idUsuario, { body, params = { id: "1" }, query = {} } = {}) {
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, params, body, query }, res);
  return res;
}

let oferta;
let libro;
let mouse;
let consolaLog;
let consolaError;

beforeEach(() => {
  jest.clearAllMocks();
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
  oferta = conUpdate({
    id: 1,
    id_publicacion_pedida: 1,
    id_publicacion_ofrecida: 8,
    id_usuario: 3,
    id_negociacion: 1,
    estado: "pendiente",
    confirma_pedida: false,
    confirma_ofrecida: false,
  });
  libro = conUpdate({ id: 1, id_usuario: 1, titulo: "Calculo I", categoria: "libros", estado_publicacion: "disponible" });
  mouse = conUpdate({ id: 8, id_usuario: 3, titulo: "Mouse", categoria: "electronica", estado_publicacion: "disponible" });
  models.ofertas.findByPk.mockResolvedValue(oferta);
  models.ofertas.count.mockResolvedValue(0);
  models.publicaciones.findByPk.mockImplementation(async (id) => ({ 1: libro, 8: mouse })[id] || null);
});

afterEach(() => {
  consolaLog.mockRestore();
  consolaError.mockRestore();
});

describe("Enviar una oferta", () => {
  const cuerpo = { id_publicacion_pedida: 1, id_publicacion_ofrecida: 8 };

  test("sin los dos ids responde 400", async () => {
    const sinCuerpo = await pedir(postOferta, 3);
    const sinOfrecida = await pedir(postOferta, 3, { body: { id_publicacion_pedida: 1 } });

    expect(sinCuerpo.status).toHaveBeenCalledWith(400);
    expect(sinOfrecida.status).toHaveBeenCalledWith(400);
  });

  test("un objeto ofrecido que no existe responde 404", async () => {
    const res = await pedir(postOferta, 3, { body: { ...cuerpo, id_publicacion_ofrecida: 99 } });

    expect(res.status).toHaveBeenCalledWith(404);
    expect(models.ofertas.count).not.toHaveBeenCalled();
  });

  test("un objeto que ya esta en otra oferta pendiente responde 409", async () => {
    models.ofertas.count.mockResolvedValue(1);

    const res = await pedir(postOferta, 3, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.ofertas.create).not.toHaveBeenCalled();
  });

  test("crea la oferta pendiente y la une a su negociacion", async () => {
    models.ofertas.create.mockResolvedValue(oferta);

    const res = await pedir(postOferta, 3, { body: cuerpo });

    expect(models.ofertas.create).toHaveBeenCalledWith({
      id_publicacion_pedida: 1,
      id_publicacion_ofrecida: 8,
      id_usuario: 3,
      estado: "pendiente",
    });
    expect(oferta.update).toHaveBeenCalledWith({ id_negociacion: 1 });
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test("dos ofertas a la vez con el mismo objeto responden 409", async () => {
    models.ofertas.create.mockRejectedValue(
      Object.assign(new Error("duplicado"), { name: "SequelizeUniqueConstraintError" }),
    );

    const res = await pedir(postOferta, 3, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("un fallo inesperado al crear responde 500", async () => {
    models.ofertas.create.mockRejectedValue(new Error("caida"));

    const res = await pedir(postOferta, 3, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Listar ofertas", () => {
  test("las recibidas dejan solo las que le toca responder a la persona", async () => {
    const paraMi = { id: 5, id_usuario: 3, pedida: { id_usuario: 1 }, ofrecida: { id_usuario: 3 } };
    const paraOtra = { id: 6, id_usuario: 1, pedida: { id_usuario: 1 }, ofrecida: { id_usuario: 3 } };
    models.ofertas.findAll.mockResolvedValue([paraMi, paraOtra]);
    const res = crearRespuesta();

    await getOfertasRecibidas({ usuario: { id: 1 } }, res);

    expect(models.ofertas.findAll.mock.calls[0][0].where.id_usuario).toEqual({ [Op.ne]: 1 });
    expect(res.json).toHaveBeenCalledWith([paraMi]);
  });

  test("las recibidas con un fallo responden 500", async () => {
    models.ofertas.findAll.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await getOfertasRecibidas({ usuario: { id: 1 } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });

  test("las enviadas son las de la persona", async () => {
    models.ofertas.findAll.mockResolvedValue([{ id: 5 }]);
    const res = crearRespuesta();

    await getOfertasEnviadas({ usuario: { id: 3 } }, res);

    expect(models.ofertas.findAll.mock.calls[0][0].where.id_usuario).toBe(3);
    expect(res.json).toHaveBeenCalledWith([{ id: 5 }]);
  });

  test("las enviadas con un fallo responden 500", async () => {
    models.ofertas.findAll.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await getOfertasEnviadas({ usuario: { id: 3 } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Aceptar una oferta", () => {
  test("con un id no valido responde 400", async () => {
    const res = await pedir(putOfertaAceptada, 1, { params: { id: "x" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una oferta que no existe responde 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una oferta ya respondida responde 409", async () => {
    oferta.estado = "rechazada";

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("si falta la publicacion pedida responde 404", async () => {
    oferta.id_publicacion_pedida = 99;

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("si falta la publicacion ofrecida responde 404", async () => {
    oferta.id_publicacion_ofrecida = 99;

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("quien envio la oferta no puede aceptarla", async () => {
    const res = await pedir(putOfertaAceptada, 3);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("si la pedida ya no esta disponible responde 409", async () => {
    libro.estado_publicacion = "reservado";

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("si la ofrecida ya no esta disponible responde 409", async () => {
    mouse.estado_publicacion = "oculto";

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("acepta, acuerda las dos publicaciones y cancela las otras ofertas pendientes", async () => {
    const res = await pedir(putOfertaAceptada, 1);

    expect(oferta.estado).toBe("aceptada");
    expect(libro.estado_publicacion).toBe("acordado");
    expect(mouse.estado_publicacion).toBe("acordado");
    const [cambios, opciones] = models.ofertas.update.mock.calls[0];
    expect(cambios).toEqual({ estado: "cancelada" });
    expect(opciones.where.id).toEqual({ [Op.ne]: 1 });
    expect(res.json.mock.calls[0][0].oferta).toBe(oferta);
  });

  test("un fallo inesperado responde 500", async () => {
    models.ofertas.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(putOfertaAceptada, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Rechazar o cancelar una oferta", () => {
  test("con un id no valido responde 400", async () => {
    const res = await pedir(putOfertaRechazada, 1, { params: { id: "0" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una oferta que no existe responde 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const res = await pedir(putOfertaCancelada, 3);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una oferta ya respondida responde 409", async () => {
    oferta.estado = "aceptada";

    const res = await pedir(putOfertaCancelada, 3);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("quien envio la oferta no puede rechazarla", async () => {
    const res = await pedir(putOfertaRechazada, 3);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("si ya no existe una publicacion nadie es receptor y no se rechaza", async () => {
    oferta.id_publicacion_pedida = 99;

    const res = await pedir(putOfertaRechazada, 1);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("quien recibe la oferta la rechaza", async () => {
    const res = await pedir(putOfertaRechazada, 1);

    expect(oferta.estado).toBe("rechazada");
    expect(res.json.mock.calls[0][0].mensaje).toBe("Rechazaste la oferta");
  });

  test("quien recibe la oferta no puede cancelarla", async () => {
    const res = await pedir(putOfertaCancelada, 1);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("quien envio la oferta la cancela", async () => {
    const res = await pedir(putOfertaCancelada, 3);

    expect(oferta.estado).toBe("cancelada");
    expect(res.json.mock.calls[0][0].mensaje).toBe("Cancelaste la oferta");
  });

  test("un fallo inesperado responde 500", async () => {
    models.ofertas.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(putOfertaCancelada, 3);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Contraoferta: casos que faltan", () => {
  const cuerpo = { id_publicacion_ofrecida: 7 };

  test("con un id no valido responde 400", async () => {
    const res = await pedir(postContraoferta, 1, { params: { id: "x" }, body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una oferta que no existe responde 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const res = await pedir(postContraoferta, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("si falta la publicacion pedida responde 404", async () => {
    oferta.id_publicacion_pedida = 99;

    const res = await pedir(postContraoferta, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("si falta la publicacion ofrecida actual responde 404", async () => {
    oferta.id_publicacion_ofrecida = 99;

    const res = await pedir(postContraoferta, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("un objeto nuevo que no existe responde 404 sin contar ofertas", async () => {
    const res = await pedir(postContraoferta, 1, { body: { id_publicacion_ofrecida: 99 } });

    expect(res.status).toHaveBeenCalledWith(404);
    expect(models.ofertas.count).not.toHaveBeenCalled();
  });

  test("un objeto nuevo que ya esta en otra oferta pendiente responde 409", async () => {
    const mandil = conUpdate({ id: 7, id_usuario: 3, estado_publicacion: "disponible" });
    models.publicaciones.findByPk.mockImplementation(async (id) => ({ 1: libro, 7: mandil, 8: mouse })[id] || null);
    models.ofertas.count.mockResolvedValue(2);

    const res = await pedir(postContraoferta, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("dos contraofertas a la vez con el mismo objeto responden 409", async () => {
    models.ofertas.findByPk.mockRejectedValue(
      Object.assign(new Error("duplicado"), { name: "SequelizeUniqueConstraintError" }),
    );

    const res = await pedir(postContraoferta, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("un fallo inesperado responde 500", async () => {
    models.ofertas.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(postContraoferta, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(500);
  });

  test("sin cuerpo pide el objeto de la contraoferta", async () => {
    const res = await pedir(postContraoferta, 1);

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

describe("Historial de la negociacion: casos que faltan", () => {
  test("con un id no valido responde 400", async () => {
    const res = await pedir(getHistorialOferta, 1, { params: { id: "x" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una oferta que no existe responde 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const res = await pedir(getHistorialOferta, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("un fallo inesperado responde 500", async () => {
    models.ofertas.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(getHistorialOferta, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });

  test("la persona que ofrece el primer objeto tambien ve el historial", async () => {
    const propuesta = conUpdate({
      id: 1,
      estado: "pendiente",
      pedida: { id_usuario: 1 },
      ofrecida: { id_usuario: 3 },
    });
    propuesta.toJSON = () => ({ id: 1 });
    models.ofertas.findAll.mockResolvedValue([propuesta]);
    const res = crearRespuesta();

    await getHistorialOferta({ usuario: { id: 3 }, params: { id: "1" } }, res);

    expect(res.json.mock.calls[0][0].abierta).toBe(true);
  });
});

describe("Confirmar la entrega: casos que faltan", () => {
  beforeEach(() => {
    oferta.estado = "aceptada";
    libro.estado_publicacion = "acordado";
    mouse.estado_publicacion = "acordado";
  });

  test("con un id no valido responde 400", async () => {
    const res = await pedir(putOfertaEntrega, 1, { params: { id: "x" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una oferta que no existe responde 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const res = await pedir(putOfertaEntrega, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("si falta una publicacion responde 404", async () => {
    oferta.id_publicacion_pedida = 99;

    const res = await pedir(putOfertaEntrega, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("si falta la publicacion ofrecida responde 404", async () => {
    oferta.id_publicacion_ofrecida = 99;

    const res = await pedir(putOfertaEntrega, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("al completar quien ofrece, la otra parte del historial es el dueno de la pedida", async () => {
    oferta.confirma_pedida = true;

    await pedir(putOfertaEntrega, 3);

    const filas = models.historial.bulkCreate.mock.calls[0][0];
    expect(filas.every((fila) => fila.id_usuario === 3 && fila.id_otro_usuario === 1)).toBe(true);
  });

  test("al completar el dueno de la pedida, la otra parte es quien ofrece", async () => {
    oferta.confirma_ofrecida = true;

    await pedir(putOfertaEntrega, 1);

    const filas = models.historial.bulkCreate.mock.calls[0][0];
    expect(filas.every((fila) => fila.id_usuario === 1 && fila.id_otro_usuario === 3)).toBe(true);
  });

  test("un fallo inesperado responde 500", async () => {
    models.ofertas.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(putOfertaEntrega, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Cancelar un intercambio acordado: casos que faltan", () => {
  test("con un id no valido responde 400", async () => {
    const res = await pedir(putOfertaAnulada, 1, { params: { id: "x" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("sin cuerpo ni motivo responde 400", async () => {
    oferta.estado = "aceptada";

    const res = await pedir(putOfertaAnulada, 1);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una oferta que no existe responde 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const res = await pedir(putOfertaAnulada, 1, { body: { motivo: "No puedo" } });

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("un fallo inesperado responde 500", async () => {
    models.ofertas.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(putOfertaAnulada, 1, { body: { motivo: "No puedo" } });

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
