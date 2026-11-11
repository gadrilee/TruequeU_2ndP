jest.mock("../database/sequelize", () => ({
  models: {
    ofertas: { findByPk: jest.fn() },
    publicaciones: { findByPk: jest.fn() },
    calificaciones: { findOne: jest.fn(), create: jest.fn() },
  },
}));

const { models } = require("../database/sequelize");
const {
  getMiCalificacion,
  postCalificacion,
  getResumenCalificaciones,
} = require("./calificaciones.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

async function llamar(controlador, idUsuario, { body = {}, query = {} } = {}) {
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, body, query }, res);
  return res;
}

let oferta;

beforeEach(() => {
  jest.clearAllMocks();
  oferta = { id: 1, id_publicacion_pedida: 1, id_publicacion_ofrecida: 8, id_usuario: 3, estado: "completada" };
  models.ofertas.findByPk.mockResolvedValue(oferta);
  models.publicaciones.findByPk.mockImplementation(async (id) =>
    ({ 1: { id: 1, id_usuario: 1 }, 8: { id: 8, id_usuario: 3 } })[id] || null,
  );
  models.calificaciones.findOne.mockResolvedValue(null);
  models.calificaciones.create.mockImplementation(async (datos) => ({ id: 10, ...datos }));
});

describe("Calificar un intercambio", () => {
  const cuerpo = { id_oferta: 1, puntaje: 5, comentario: "Todo bien" };

  test("quien pidió el objeto califica a quien lo ofreció", async () => {
    const res = await llamar(postCalificacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(201);
    expect(models.calificaciones.create).toHaveBeenCalledWith({
      id_oferta: 1,
      id_usuario: 1,
      id_calificado: 3,
      puntaje: 5,
      comentario: "Todo bien",
    });
  });

  test("quien ofreció el objeto califica a quien lo pidió", async () => {
    const res = await llamar(postCalificacion, 3, { body: { id_oferta: 1, puntaje: 4 } });

    expect(res.status).toHaveBeenCalledWith(201);
    expect(models.calificaciones.create.mock.calls[0][0]).toMatchObject({
      id_usuario: 3,
      id_calificado: 1,
      puntaje: 4,
      comentario: null,
    });
  });

  test("un tercero recibe 403 y no se guarda nada", async () => {
    const res = await llamar(postCalificacion, 2, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(403);
    expect(models.calificaciones.create).not.toHaveBeenCalled();
  });

  test("un intercambio cancelado recibe 409 y no se guarda nada", async () => {
    oferta.estado = "anulada";
    const res = await llamar(postCalificacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({ error: "Un intercambio cancelado no se puede calificar" });
    expect(models.calificaciones.create).not.toHaveBeenCalled();
  });

  test("un intercambio que no se completó recibe 409", async () => {
    oferta.estado = "aceptada";
    const res = await llamar(postCalificacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.calificaciones.create).not.toHaveBeenCalled();
  });

  test("una segunda calificación recibe 409 y no se guarda otra", async () => {
    models.calificaciones.findOne.mockResolvedValue({ id: 9 });
    const res = await llamar(postCalificacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({ error: "Ya calificaste este intercambio" });
    expect(models.calificaciones.create).not.toHaveBeenCalled();
  });

  test("si dos pedidos llegan juntos, la base rechaza el segundo con 409", async () => {
    models.calificaciones.create.mockRejectedValue({ name: "SequelizeUniqueConstraintError" });
    const res = await llamar(postCalificacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({ error: "Ya calificaste este intercambio" });
  });

  test("un puntaje fuera de 1 a 5 recibe 400", async () => {
    const res = await llamar(postCalificacion, 1, { body: { id_oferta: 1, puntaje: 6 } });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.calificaciones.create).not.toHaveBeenCalled();
  });

  test("sin un id de oferta válido recibe 400", async () => {
    const res = await llamar(postCalificacion, 1, { body: { id_oferta: "x", puntaje: 5 } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("si la oferta no existe recibe 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);
    const res = await llamar(postCalificacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(404);
  });
});

describe("Ver mi calificación de un intercambio", () => {
  test("devuelve la que hice o null", async () => {
    models.calificaciones.findOne.mockResolvedValue({ id: 9, puntaje: 5 });
    const con = await llamar(getMiCalificacion, 1, { query: { id_oferta: "1" } });
    expect(con.json).toHaveBeenCalledWith({ mia: { id: 9, puntaje: 5 } });
    expect(models.calificaciones.findOne.mock.calls[0][0].where).toEqual({ id_oferta: 1, id_usuario: 1 });

    models.calificaciones.findOne.mockResolvedValue(null);
    const sin = await llamar(getMiCalificacion, 1, { query: { id_oferta: "1" } });
    expect(sin.json).toHaveBeenCalledWith({ mia: null });
  });

  test("sin un id de oferta válido recibe 400", async () => {
    const res = await llamar(getMiCalificacion, 1, { query: {} });

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

describe("Resumen de calificaciones de una persona", () => {
  test("devuelve el promedio con un decimal y la cantidad", async () => {
    models.calificaciones.findOne.mockResolvedValue({ cantidad: "3", promedio: "4.3333333333333333" });
    const res = await llamar(getResumenCalificaciones, 1, { query: { id_usuario: "1" } });

    expect(res.json).toHaveBeenCalledWith({ cantidad: 3, promedio: 4.3 });
    expect(models.calificaciones.findOne.mock.calls[0][0].where).toEqual({ id_calificado: 1 });
  });

  test("sin calificaciones devuelve cantidad 0 y promedio null", async () => {
    models.calificaciones.findOne.mockResolvedValue({ cantidad: "0", promedio: null });
    const res = await llamar(getResumenCalificaciones, 1, { query: { id_usuario: "1" } });

    expect(res.json).toHaveBeenCalledWith({ cantidad: 0, promedio: null });
  });

  test("sin un id de persona válido recibe 400", async () => {
    const res = await llamar(getResumenCalificaciones, 1, { query: { id_usuario: "0" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });
});
