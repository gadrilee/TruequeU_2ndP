jest.mock("../database/sequelize", () => ({
  models: {
    notificaciones: { findAll: jest.fn(), update: jest.fn() },
  },
}));

const { models } = require("../database/sequelize");
const { getNotificaciones, putNotificacionLeida } = require("./notificaciones.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe("Avisos", () => {
  test("lista solo los avisos de la persona, los mas nuevos primero", async () => {
    models.notificaciones.findAll.mockResolvedValue([{ id: 2 }, { id: 1 }]);
    const res = crearRespuesta();

    await getNotificaciones({ usuario: { id: 3 } }, res);

    const consulta = models.notificaciones.findAll.mock.calls[0][0];
    expect(consulta.where).toEqual({ id_usuario: 3 });
    expect(consulta.order[0]).toEqual(["creado_en", "DESC"]);
    expect(res.json).toHaveBeenCalledWith([{ id: 2 }, { id: 1 }]);
  });

  test("marca un aviso propio como leido", async () => {
    models.notificaciones.update.mockResolvedValue([1]);
    const res = crearRespuesta();

    await putNotificacionLeida({ usuario: { id: 3 }, params: { id: "7" } }, res);

    expect(models.notificaciones.update).toHaveBeenCalledWith(
      { leida: true },
      { where: { id: 7, id_usuario: 3 } },
    );
    expect(res.json).toHaveBeenCalledWith({ ok: true });
  });

  test("un aviso de otra persona da 404", async () => {
    models.notificaciones.update.mockResolvedValue([0]);
    const res = crearRespuesta();

    await putNotificacionLeida({ usuario: { id: 3 }, params: { id: "7" } }, res);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("un id que no es numero da 400", async () => {
    const res = crearRespuesta();

    await putNotificacionLeida({ usuario: { id: 3 }, params: { id: "abc" } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.notificaciones.update).not.toHaveBeenCalled();
  });
});

describe("Avisos: errores inesperados", () => {
  let consolaError;

  beforeEach(() => {
    consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
  });

  afterEach(() => {
    consolaError.mockRestore();
  });

  test("listar con un fallo responde 500", async () => {
    models.notificaciones.findAll.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await getNotificaciones({ usuario: { id: 1 } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });

  test("marcar como leido con un fallo responde 500", async () => {
    models.notificaciones.update.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await putNotificacionLeida({ params: { id: "3" }, usuario: { id: 1 } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
