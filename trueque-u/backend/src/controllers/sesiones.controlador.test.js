jest.mock("../database/sequelize", () => ({
  models: {
    usuarios: { findOne: jest.fn() },
    sesiones: { update: jest.fn() },
  },
}));
jest.mock("../services/contrasena.servicio", () => ({
  coincide: jest.fn(),
}));
jest.mock("../services/sesion.servicio", () => ({
  crearSesion: jest.fn(),
}));
jest.mock("../services/token.servicio", () => ({
  firmarToken: jest.fn(() => "token"),
}));

const { models } = require("../database/sequelize");
const { coincide } = require("../services/contrasena.servicio");
const { crearSesion } = require("../services/sesion.servicio");
const { postSesion, getSesionActual, deleteSesion } = require("./sesiones.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

beforeEach(() => {
  jest.clearAllMocks();
  coincide.mockResolvedValue(true);
  crearSesion.mockResolvedValue("sesion-1");
});

describe("Iniciar sesion", () => {
  const cuerpo = { correo: "eudenia@correo.com", contrasena: "eude1234" };

  test("una cuenta activa inicia sesion", async () => {
    models.usuarios.findOne.mockResolvedValue({ id: 1, nombre: "Eudenia", correo: cuerpo.correo, eliminado_en: null });
    const res = crearRespuesta();

    await postSesion({ body: cuerpo }, res);

    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ token: "token" }));
  });

  test("una cuenta eliminada no puede iniciar sesion", async () => {
    models.usuarios.findOne.mockResolvedValue({ id: 1, eliminado_en: new Date() });
    const res = crearRespuesta();

    await postSesion({ body: cuerpo }, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(crearSesion).not.toHaveBeenCalled();
  });

  test("sin correo o sin contrasena responde 400", async () => {
    const res = crearRespuesta();

    await postSesion({}, res);
    await postSesion({ body: { correo: "a@correo.com", contrasena: 5 } }, res);

    expect(res.status).toHaveBeenCalledTimes(2);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.usuarios.findOne).not.toHaveBeenCalled();
  });

  test("un correo sin cuenta responde 401", async () => {
    models.usuarios.findOne.mockResolvedValue(null);
    const res = crearRespuesta();

    await postSesion({ body: cuerpo }, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test("una contrasena incorrecta responde 401", async () => {
    models.usuarios.findOne.mockResolvedValue({ id: 1, eliminado_en: null });
    coincide.mockResolvedValue(false);
    const res = crearRespuesta();

    await postSesion({ body: cuerpo }, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test("un fallo inesperado responde 500", async () => {
    models.usuarios.findOne.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await postSesion({ body: cuerpo }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Ver la sesion actual", () => {
  test("devuelve el usuario de la sesion", () => {
    const res = crearRespuesta();

    getSesionActual({ usuario: { id: 1, nombre: "Eudenia", correo: "eude@correo.com" } }, res);

    expect(res.json).toHaveBeenCalledWith({
      usuario: expect.objectContaining({ id: 1, nombre: "Eudenia" }),
    });
  });
});

describe("Cerrar sesion", () => {
  test("marca la sesion como cerrada", async () => {
    models.sesiones.update.mockResolvedValue([1]);
    const res = crearRespuesta();

    await deleteSesion({ sesionId: "sesion-1", usuario: { id: 1 } }, res);

    expect(models.sesiones.update).toHaveBeenCalledWith(
      { cerrada_en: expect.any(Date) },
      { where: { id: "sesion-1" } },
    );
    expect(res.json).toHaveBeenCalledWith({ ok: true });
  });

  test("un fallo inesperado responde 500", async () => {
    models.sesiones.update.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await deleteSesion({ sesionId: "sesion-1", usuario: { id: 1 } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
