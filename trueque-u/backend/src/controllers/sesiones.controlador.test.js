jest.mock("../database/sequelize", () => ({
  models: {
    usuarios: { findOne: jest.fn() },
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
const { postSesion } = require("./sesiones.controlador");

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
});
