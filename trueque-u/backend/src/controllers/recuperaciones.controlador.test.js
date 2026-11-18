jest.mock("../database/sequelize", () => ({
  models: { usuarios: { findOne: jest.fn() } },
}));
jest.mock("../services/contrasena.servicio", () => ({ cifrar: jest.fn() }));
jest.mock("../services/correo.servicio", () => ({ enviarCorreo: jest.fn() }));
jest.mock("../utils/contrasenaTemporal", () => ({
  generarContrasenaTemporal: jest.fn(() => "Temp1234"),
}));

const { models } = require("../database/sequelize");
const { cifrar } = require("../services/contrasena.servicio");
const { enviarCorreo } = require("../services/correo.servicio");
const { postRecuperacion } = require("./recuperaciones.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

let consolaLog;
let consolaError;

beforeEach(() => {
  jest.clearAllMocks();
  cifrar.mockResolvedValue("hash-nuevo");
  enviarCorreo.mockResolvedValue();
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consolaLog.mockRestore();
  consolaError.mockRestore();
});

describe("Recuperar la contrasena", () => {
  const usuario = () => ({ id: 4, nombre: "Eudenia", correo: "eude@correo.com", update: jest.fn() });

  test("un correo no valido responde 400", async () => {
    const res = crearRespuesta();

    await postRecuperacion({ body: { correo: "malo" } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.usuarios.findOne).not.toHaveBeenCalled();
  });

  test("sin cuerpo responde 400", async () => {
    const res = crearRespuesta();

    await postRecuperacion({}, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("un correo sin cuenta responde 404", async () => {
    models.usuarios.findOne.mockResolvedValue(null);
    const res = crearRespuesta();

    await postRecuperacion({ body: { correo: "nadie@correo.com" } }, res);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("guarda la contrasena nueva cifrada y la envia por correo", async () => {
    const cuenta = usuario();
    models.usuarios.findOne.mockResolvedValue(cuenta);
    const res = crearRespuesta();

    await postRecuperacion({ body: { correo: "  Eude@Correo.com " } }, res);

    expect(models.usuarios.findOne).toHaveBeenCalledWith({ where: { correo: "eude@correo.com" } });
    expect(cuenta.update).toHaveBeenCalledWith({ contrasena_hash: "hash-nuevo" });
    expect(enviarCorreo).toHaveBeenCalledWith(
      "eude@correo.com",
      "Tu nueva contraseña de Trueque U",
      expect.stringContaining("Tu nueva contraseña es: Temp1234"),
    );
    expect(res.json).toHaveBeenCalledWith({
      ok: true,
      mensaje: "Te enviamos una contraseña nueva a tu correo",
    });
  });

  test("si el correo no se puede enviar responde 502", async () => {
    models.usuarios.findOne.mockResolvedValue(usuario());
    enviarCorreo.mockRejectedValue(new Error("smtp caido"));
    const res = crearRespuesta();

    await postRecuperacion({ body: { correo: "eude@correo.com" } }, res);

    expect(res.status).toHaveBeenCalledWith(502);
    expect(res.json).toHaveBeenCalledWith({ error: "No se pudo enviar el correo. Intenta de nuevo." });
  });

  test("un fallo inesperado responde 500", async () => {
    models.usuarios.findOne.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await postRecuperacion({ body: { correo: "eude@correo.com" } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ error: "Error al recuperar la contraseña" });
  });
});
