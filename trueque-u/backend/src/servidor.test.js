const mockListen = jest.fn();
const mockAuthenticate = jest.fn();

jest.mock("./aplicacion", () => ({ listen: (...args) => mockListen(...args) }));
jest.mock("./configuration/entorno", () => ({ puerto: 4321 }));
jest.mock("./database/sequelize", () => ({
  sequelize: { authenticate: (...args) => mockAuthenticate(...args) },
}));

let salida;
let consolaError;
let consolaLog;

function cargarServidor() {
  jest.isolateModules(() => {
    require("./servidor");
  });
  return new Promise((resolver) => setImmediate(resolver));
}

beforeEach(() => {
  jest.clearAllMocks();
  salida = jest.spyOn(process, "exit").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
});

afterEach(() => {
  salida.mockRestore();
  consolaError.mockRestore();
  consolaLog.mockRestore();
});

describe("Servidor", () => {
  test("con la base de datos disponible escucha en el puerto configurado", async () => {
    mockAuthenticate.mockResolvedValue();

    await cargarServidor();

    expect(mockListen).toHaveBeenCalledWith(4321, expect.any(Function));
    mockListen.mock.calls[0][1]();
    expect(consolaLog).toHaveBeenCalledWith("Trueque U API escuchando en http://localhost:4321");
    expect(salida).not.toHaveBeenCalled();
  });

  test("si falla la conexion muestra el detalle y termina con codigo 1", async () => {
    const error = new Error("sin conexion");
    error.original = {
      name: "AggregateError",
      code: "ECONNREFUSED",
      errors: [{ code: "ECONNREFUSED", address: "::1", port: 5432 }],
    };
    mockAuthenticate.mockRejectedValue(error);

    await cargarServidor();

    expect(consolaError).toHaveBeenCalledWith("No se pudo conectar a PostgreSQL:", "sin conexion");
    expect(consolaError).toHaveBeenCalledWith("Tipo:", "AggregateError", "| Código:", "ECONNREFUSED");
    expect(consolaError).toHaveBeenCalledWith(" -", "ECONNREFUSED", "::1:5432");
    expect(salida).toHaveBeenCalledWith(1);
  });

  test("un error sin detalle original ni intentos tambien termina con codigo 1", async () => {
    const error = new Error("fallo simple");
    error.code = "XX";
    mockAuthenticate.mockRejectedValue(error);

    await cargarServidor();

    expect(consolaError).toHaveBeenCalledWith("Tipo:", "Error", "| Código:", "XX");
    expect(salida).toHaveBeenCalledWith(1);
  });
});
