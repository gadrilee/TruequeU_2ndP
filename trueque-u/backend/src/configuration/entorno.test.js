jest.mock("dotenv", () => ({ config: jest.fn() }));

const ENV_ORIGINAL = process.env;

function cargarEntorno(variables) {
  process.env = { ...variables };
  let entorno;
  jest.isolateModules(() => {
    entorno = require("./entorno");
  });
  return entorno;
}

afterEach(() => {
  process.env = ENV_ORIGINAL;
});

describe("Configuracion del entorno", () => {
  test("sin variables usa los valores por defecto", () => {
    const entorno = cargarEntorno({});

    expect(entorno.puerto).toBe(3000);
    expect(entorno.jwtSecreto).toBe("trueque-u-secreto-solo-para-desarrollo");
    expect(entorno.duracionSesionDias).toBe(7);
    expect(entorno.correo).toEqual({ usuario: undefined, clave: undefined });
    expect(entorno.baseDeDatos).toEqual({
      host: "localhost",
      port: 5432,
      database: "trueque_u",
      user: "postgres",
      password: undefined,
    });
  });

  test("con variables sueltas las usa", () => {
    const entorno = cargarEntorno({
      PUERTO: "4000",
      JWT_SECRETO: "otro",
      CORREO_USUARIO: "a@gmail.com",
      CORREO_CLAVE: "clave",
      BD_HOST: "servidor",
      BD_PUERTO: "6543",
      BD_NOMBRE: "mi_base",
      BD_USUARIO: "yo",
      BD_CONTRASENA: "secreta",
    });

    expect(entorno.puerto).toBe("4000");
    expect(entorno.jwtSecreto).toBe("otro");
    expect(entorno.correo).toEqual({ usuario: "a@gmail.com", clave: "clave" });
    expect(entorno.baseDeDatos).toEqual({
      host: "servidor",
      port: 6543,
      database: "mi_base",
      user: "yo",
      password: "secreta",
    });
  });

  test("con BD_URL usa la cadena de conexion segura y sin channel_binding", () => {
    const entorno = cargarEntorno({
      BD_URL: "postgres://u:p@host/db?sslmode=require&channel_binding=require",
    });

    expect(entorno.baseDeDatos).toEqual({
      connectionString: "postgres://u:p@host/db?sslmode=verify-full",
    });
  });
});
