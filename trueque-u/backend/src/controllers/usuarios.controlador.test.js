const mockTransaccion = jest.fn();

jest.mock("../database/sequelize", () => ({
  sequelize: { transaction: (trabajo) => mockTransaccion(trabajo) },
  models: {
    usuarios: { findOne: jest.fn(), findByPk: jest.fn(), create: jest.fn() },
  },
}));
jest.mock("../services/contrasena.servicio", () => ({
  cifrar: jest.fn(),
  coincide: jest.fn(),
}));
jest.mock("../services/sesion.servicio", () => ({ crearSesion: jest.fn() }));
jest.mock("../services/token.servicio", () => ({ firmarToken: jest.fn(() => "token") }));

const { models } = require("../database/sequelize");
const { cifrar, coincide } = require("../services/contrasena.servicio");
const { crearSesion } = require("../services/sesion.servicio");
const { firmarToken } = require("../services/token.servicio");
const { postUsuario, putContrasena } = require("./usuarios.controlador");

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
  cifrar.mockResolvedValue("hash");
  coincide.mockResolvedValue(true);
  crearSesion.mockResolvedValue("sesion-1");
  mockTransaccion.mockImplementation((trabajo) => trabajo("tx"));
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consolaLog.mockRestore();
  consolaError.mockRestore();
});

describe("Registrar una cuenta", () => {
  const cuerpo = {
    nombre: "  Eudenia ",
    correo: " Eude@Correo.com ",
    contrasena: "eude1234",
    telefono: " 71234567 ",
  };

  test.each([
    ["sin cuerpo", undefined, "Escribe tu nombre (mínimo 2 letras)"],
    ["nombre que no es texto", { ...cuerpo, nombre: 5 }, "Escribe tu nombre (mínimo 2 letras)"],
    ["nombre muy corto", { ...cuerpo, nombre: " a " }, "Escribe tu nombre (mínimo 2 letras)"],
    ["correo no valido", { ...cuerpo, correo: "malo" }, "Correo no válido"],
    ["contrasena corta", { ...cuerpo, contrasena: "123" }, "La contraseña debe tener al menos 6 caracteres"],
    ["telefono no valido", { ...cuerpo, telefono: "123" }, "El teléfono debe tener 8 dígitos"],
  ])("%s responde 400", async (nombre, body, error) => {
    const res = crearRespuesta();

    await postUsuario({ body }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error });
    expect(models.usuarios.findOne).not.toHaveBeenCalled();
  });

  test("un correo repetido responde 409", async () => {
    models.usuarios.findOne.mockResolvedValue({ id: 1 });
    const res = crearRespuesta();

    await postUsuario({ body: cuerpo }, res);

    expect(models.usuarios.findOne).toHaveBeenCalledWith({ where: { correo: "eude@correo.com" } });
    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("crea la cuenta con telefono y deja la sesion iniciada", async () => {
    models.usuarios.findOne.mockResolvedValue(null);
    models.usuarios.create.mockResolvedValue({ id: 7, nombre: "Eudenia", correo: "eude@correo.com" });
    const res = crearRespuesta();

    await postUsuario({ body: cuerpo }, res);

    expect(models.usuarios.create).toHaveBeenCalledWith(
      { nombre: "Eudenia", correo: "eude@correo.com", contrasena_hash: "hash", telefono: "71234567" },
      { transaction: "tx" },
    );
    expect(crearSesion).toHaveBeenCalledWith(7, "tx");
    expect(firmarToken).toHaveBeenCalledWith({ usuarioId: 7, sesionId: "sesion-1" });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ token: "token" }));
  });

  test.each([[undefined], [null], [""]])("sin telefono (%p) lo guarda como null", async (telefono) => {
    models.usuarios.findOne.mockResolvedValue(null);
    models.usuarios.create.mockResolvedValue({ id: 7, nombre: "Eudenia", correo: "eude@correo.com" });

    await postUsuario({ body: { ...cuerpo, telefono } }, crearRespuesta());

    expect(models.usuarios.create.mock.calls[0][0].telefono).toBeNull();
  });

  test("dos registros a la vez con el mismo correo responden 409", async () => {
    models.usuarios.findOne.mockResolvedValue(null);
    mockTransaccion.mockRejectedValue(Object.assign(new Error("duplicado"), { name: "SequelizeUniqueConstraintError" }));
    const res = crearRespuesta();

    await postUsuario({ body: cuerpo }, res);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("un fallo inesperado responde 500", async () => {
    models.usuarios.findOne.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await postUsuario({ body: cuerpo }, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ error: "Error al crear la cuenta" });
  });
});

describe("Cambiar la contrasena", () => {
  const req = (body) => ({ body, usuario: { id: 3 } });

  test("sin contrasena actual responde 400", async () => {
    const res = crearRespuesta();

    await putContrasena({ usuario: { id: 3 } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: "Escribe tu contraseña actual" });
  });

  test("una contrasena nueva corta responde 400", async () => {
    const res = crearRespuesta();

    await putContrasena(req({ contrasenaActual: "vieja", contrasenaNueva: "123" }), res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("si la cuenta ya no existe responde 400", async () => {
    models.usuarios.findByPk.mockResolvedValue(null);
    const res = crearRespuesta();

    await putContrasena(req({ contrasenaActual: "vieja", contrasenaNueva: "nueva123" }), res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: "La contraseña actual no es correcta" });
  });

  test("una contrasena actual incorrecta responde 400", async () => {
    models.usuarios.findByPk.mockResolvedValue({ contrasena_hash: "h", update: jest.fn() });
    coincide.mockResolvedValue(false);
    const res = crearRespuesta();

    await putContrasena(req({ contrasenaActual: "vieja", contrasenaNueva: "nueva123" }), res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("guarda la contrasena nueva cifrada", async () => {
    const usuario = { id: 3, contrasena_hash: "h", update: jest.fn() };
    models.usuarios.findByPk.mockResolvedValue(usuario);
    const res = crearRespuesta();

    await putContrasena(req({ contrasenaActual: "vieja", contrasenaNueva: "nueva123" }), res);

    expect(usuario.update).toHaveBeenCalledWith({ contrasena_hash: "hash" });
    expect(res.json).toHaveBeenCalledWith({ ok: true, mensaje: "Contraseña actualizada" });
  });

  test("un fallo inesperado responde 500", async () => {
    models.usuarios.findByPk.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await putContrasena(req({ contrasenaActual: "vieja", contrasenaNueva: "nueva123" }), res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
