jest.mock("../database/sequelize", () => ({
  models: {
    sesiones: { findOne: jest.fn() },
    usuarios: {},
  },
}));
jest.mock("../services/token.servicio", () => ({
  verificarToken: jest.fn(),
}));

const { models } = require("../database/sequelize");
const { verificarToken } = require("../services/token.servicio");
const { exigirSesion } = require("./autenticacion.middleware");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

beforeEach(() => {
  jest.clearAllMocks();
  verificarToken.mockReturnValue({ jti: "sesion-1" });
});

describe("Exigir sesion", () => {
  test("sin cabecera Authorization responde 401", async () => {
    const res = crearRespuesta();
    const next = jest.fn();

    await exigirSesion({ headers: {} }, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: "No has iniciado sesión" });
    expect(next).not.toHaveBeenCalled();
  });

  test("una cabecera que no es Bearer responde 401", async () => {
    const res = crearRespuesta();

    await exigirSesion({ headers: { authorization: "Basic abc" } }, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(401);
    expect(verificarToken).not.toHaveBeenCalled();
  });

  test("un token invalido responde 401", async () => {
    verificarToken.mockImplementation(() => {
      throw new Error("jwt malformed");
    });
    const res = crearRespuesta();

    await exigirSesion({ headers: { authorization: "Bearer malo" } }, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: "Sesión inválida o vencida" });
  });

  test("una sesion cerrada o vencida responde 401", async () => {
    models.sesiones.findOne.mockResolvedValue(null);
    const res = crearRespuesta();

    await exigirSesion({ headers: { authorization: "Bearer bueno" } }, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: "Sesión cerrada o vencida" });
  });

  test("una cuenta eliminada responde 401", async () => {
    models.sesiones.findOne.mockResolvedValue({ id: "sesion-1", usuario: { id: 1, eliminado_en: new Date() } });
    const res = crearRespuesta();
    const next = jest.fn();

    await exigirSesion({ headers: { authorization: "Bearer bueno" } }, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test("una sesion valida deja pasar y guarda el usuario en la peticion", async () => {
    const usuario = { id: 1, nombre: "Eudenia", eliminado_en: null };
    models.sesiones.findOne.mockResolvedValue({ id: "sesion-1", usuario });
    const req = { headers: { authorization: "Bearer bueno" } };
    const next = jest.fn();

    await exigirSesion(req, crearRespuesta(), next);

    expect(verificarToken).toHaveBeenCalledWith("bueno");
    expect(models.sesiones.findOne.mock.calls[0][0].where.id).toBe("sesion-1");
    expect(req.usuario).toBe(usuario);
    expect(req.sesionId).toBe("sesion-1");
    expect(next).toHaveBeenCalledTimes(1);
  });

  test("un fallo de la base de datos responde 500", async () => {
    models.sesiones.findOne.mockRejectedValue(new Error("caida"));
    const consola = jest.spyOn(console, "error").mockImplementation(() => {});
    const res = crearRespuesta();

    await exigirSesion({ headers: { authorization: "Bearer bueno" } }, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ error: "Error al comprobar la sesión" });
    consola.mockRestore();
  });
});
