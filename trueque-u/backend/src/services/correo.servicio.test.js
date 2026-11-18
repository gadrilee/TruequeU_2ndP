jest.mock("nodemailer", () => ({ createTransport: jest.fn() }));
jest.mock("../configuration/entorno", () => ({ correo: { usuario: undefined, clave: undefined } }));

const nodemailer = require("nodemailer");
const { correo } = require("../configuration/entorno");
const { enviarCorreo } = require("./correo.servicio");

let consola;

beforeEach(() => {
  jest.clearAllMocks();
  correo.usuario = undefined;
  correo.clave = undefined;
  consola = jest.spyOn(console, "log").mockImplementation(() => {});
});

afterEach(() => {
  consola.mockRestore();
});

describe("Enviar correo", () => {
  test("sin usuario ni clave solo muestra el mensaje en la consola", async () => {
    await enviarCorreo("a@correo.com", "Asunto", "Texto");

    expect(nodemailer.createTransport).not.toHaveBeenCalled();
    expect(consola.mock.calls[0][0]).toContain("CORREO_USUARIO CORREO_CLAVE");
    expect(consola.mock.calls[1][0]).toContain("Para: a@correo.com");
  });

  test("con usuario pero sin clave avisa solo de la clave", async () => {
    correo.usuario = "trueque@gmail.com";

    await enviarCorreo("a@correo.com", "Asunto", "Texto");

    expect(consola.mock.calls[0][0]).toContain("CORREO_CLAVE");
    expect(consola.mock.calls[0][0]).not.toContain("CORREO_USUARIO");
  });

  test("con clave pero sin usuario avisa solo del usuario", async () => {
    correo.clave = "clave";

    await enviarCorreo("a@correo.com", "Asunto", "Texto");

    expect(consola.mock.calls[0][0]).toContain("CORREO_USUARIO");
    expect(consola.mock.calls[0][0]).not.toContain("CORREO_CLAVE");
  });

  test("con los datos de Gmail envia el correo", async () => {
    correo.usuario = "trueque@gmail.com";
    correo.clave = "clave";
    const sendMail = jest.fn().mockResolvedValue({});
    nodemailer.createTransport.mockReturnValue({ sendMail });

    await enviarCorreo("a@correo.com", "Asunto", "Texto");

    expect(nodemailer.createTransport).toHaveBeenCalledWith({
      service: "gmail",
      auth: { user: "trueque@gmail.com", pass: "clave" },
    });
    expect(sendMail).toHaveBeenCalledWith({
      from: '"Trueque U" <trueque@gmail.com>',
      to: "a@correo.com",
      subject: "Asunto",
      text: "Texto",
    });
  });
});
