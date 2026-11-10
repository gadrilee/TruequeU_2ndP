jest.mock("../database/sequelize", () => ({
  sequelize: {
    transaction: jest.fn((funcion) => funcion({ LOCK: { UPDATE: "UPDATE" } })),
  },
  models: {
    usuarios: {},
    ofertas: { findByPk: jest.fn() },
    publicaciones: { findByPk: jest.fn() },
    propuestas_entrega: {
      findByPk: jest.fn(),
      findOne: jest.fn(),
      findAll: jest.fn(),
      create: jest.fn(),
    },
  },
}));

const { models } = require("../database/sequelize");
const {
  getPropuestasEntrega,
  postPropuestaEntrega,
  postContrapropuestaEntrega,
  putPropuestaEntregaAceptada,
} = require("./propuestasEntrega.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function crearPropuesta(datos) {
  const propuesta = { hora: "15:00:00", id_propuesta_anterior: null, ...datos };
  propuesta.update = jest.fn(async (cambios) => Object.assign(propuesta, cambios));
  propuesta.reload = jest.fn().mockResolvedValue(propuesta);
  propuesta.toJSON = () => ({ ...propuesta });
  return propuesta;
}

const manana = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
const cuerpo = { id_oferta: 1, fecha: manana, hora: "15:00", lugar: "Biblioteca" };

let oferta;

beforeEach(() => {
  jest.clearAllMocks();
  oferta = { id: 1, id_publicacion_pedida: 1, id_publicacion_ofrecida: 8, id_usuario: 3, estado: "aceptada" };
  models.ofertas.findByPk.mockResolvedValue(oferta);
  models.publicaciones.findByPk.mockImplementation(async (id) =>
    ({ 1: { id: 1, id_usuario: 1 }, 8: { id: 8, id_usuario: 3 } })[id] || null,
  );
  models.propuestas_entrega.findOne.mockResolvedValue(null);
  models.propuestas_entrega.create.mockImplementation(async (datos) => crearPropuesta({ id: 10, ...datos }));
});

async function llamar(controlador, idUsuario, { body = {}, params = {}, query = {} } = {}) {
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, body, params, query }, res);
  return res;
}

describe("Proponer la entrega", () => {
  test("crea una propuesta pendiente de quien la envía", async () => {
    const res = await llamar(postPropuestaEntrega, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(201);
    const datos = models.propuestas_entrega.create.mock.calls[0][0];
    expect(datos).toMatchObject({ id_oferta: 1, id_usuario: 1, estado: "pendiente", lugar: "Biblioteca" });
    expect(res.json.mock.calls[0][0].propuesta.hora).toBe("15:00");
  });

  test("un tercero recibe 403 y no se crea nada", async () => {
    const res = await llamar(postPropuestaEntrega, 2, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(403);
    expect(models.propuestas_entrega.create).not.toHaveBeenCalled();
  });

  test("con una propuesta pendiente responde 409", async () => {
    models.propuestas_entrega.findOne.mockImplementation(async ({ where }) =>
      where.estado === "pendiente" ? crearPropuesta({ id: 4, estado: "pendiente" }) : null,
    );
    const res = await llamar(postPropuestaEntrega, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.propuestas_entrega.create).not.toHaveBeenCalled();
  });

  test("si ya hay acuerdo, el mensaje habla de reprogramar y el acuerdo no se toca", async () => {
    const vigente = crearPropuesta({ id: 3, estado: "aceptada", fecha: "2020-01-01", lugar: "Otro lugar" });
    models.propuestas_entrega.findOne.mockImplementation(async ({ where }) =>
      where.estado === "aceptada" ? vigente : null,
    );
    const res = await llamar(postPropuestaEntrega, 1, { body: cuerpo });

    expect(res.json.mock.calls[0][0].mensaje).toMatch(/reprogramación/);
    expect(vigente.update).not.toHaveBeenCalled();
    expect(vigente.estado).toBe("aceptada");
  });
});

describe("Responder una propuesta", () => {
  let pendiente;

  beforeEach(() => {
    pendiente = crearPropuesta({
      id: 5,
      id_oferta: 1,
      id_usuario: 1,
      estado: "pendiente",
      fecha: manana,
      lugar: "Biblioteca",
    });
    models.propuestas_entrega.findByPk.mockResolvedValue(pendiente);
  });

  test("aceptar deja la propuesta como acuerdo vigente", async () => {
    const res = await llamar(putPropuestaEntregaAceptada, 3, { params: { id: "5" } });

    expect(pendiente.estado).toBe("aceptada");
    expect(res.status).not.toHaveBeenCalled();
  });

  test("al aceptar una reprogramación el acuerdo anterior pasa a reemplazado", async () => {
    const vigente = crearPropuesta({ id: 3, estado: "aceptada" });
    models.propuestas_entrega.findOne.mockResolvedValue(vigente);
    await llamar(putPropuestaEntregaAceptada, 3, { params: { id: "5" } });

    expect(vigente.estado).toBe("reemplazada");
    expect(pendiente.estado).toBe("aceptada");
  });

  test("quien propuso no puede aceptar su propia propuesta", async () => {
    const res = await llamar(putPropuestaEntregaAceptada, 1, { params: { id: "5" } });

    expect(res.status).toHaveBeenCalledWith(403);
    expect(pendiente.estado).toBe("pendiente");
  });

  test("contraproponer cierra la anterior y crea una nueva de quien responde", async () => {
    const res = await llamar(postContrapropuestaEntrega, 3, {
      params: { id: "5" },
      body: { fecha: manana, hora: "15:00", lugar: "Cafetería" },
    });

    expect(res.status).toHaveBeenCalledWith(201);
    expect(pendiente.estado).toBe("contrapuesta");
    const nueva = models.propuestas_entrega.create.mock.calls[0][0];
    expect(nueva).toMatchObject({
      id_usuario: 3,
      estado: "pendiente",
      lugar: "Cafetería",
      id_propuesta_anterior: 5,
    });
  });

  test("una contrapropuesta igual a la propuesta responde 409", async () => {
    const res = await llamar(postContrapropuestaEntrega, 3, {
      params: { id: "5" },
      body: { fecha: manana, hora: "15:00", lugar: "Biblioteca" },
    });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(pendiente.estado).toBe("pendiente");
  });

  test("después de completarse el intercambio ya no se responde", async () => {
    oferta.estado = "completada";
    const res = await llamar(putPropuestaEntregaAceptada, 3, { params: { id: "5" } });

    expect(res.status).toHaveBeenCalledWith(409);
  });
});

describe("Ver la coordinación", () => {
  test("solo las partes la ven", async () => {
    const res = await llamar(getPropuestasEntrega, 2, { query: { id_oferta: "1" } });

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("devuelve el historial con el acuerdo vigente y la propuesta pendiente", async () => {
    models.propuestas_entrega.findAll.mockResolvedValue([
      crearPropuesta({ id: 3, estado: "aceptada" }),
      crearPropuesta({ id: 4, estado: "pendiente" }),
    ]);
    const res = await llamar(getPropuestasEntrega, 1, { query: { id_oferta: "1" } });

    const datos = res.json.mock.calls[0][0];
    expect(datos.propuestas).toHaveLength(2);
    expect(datos.vigente.id).toBe(3);
    expect(datos.pendiente.id).toBe(4);
  });
});
