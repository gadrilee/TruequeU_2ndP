const mockQuery = jest.fn();
const mockConnect = jest.fn();
const mockPool = jest.fn();

jest.mock("pg", () => ({
  Pool: function (config) {
    mockPool(config);
    return { query: mockQuery, connect: mockConnect };
  },
}));
jest.mock("../configuration/entorno", () => ({ baseDeDatos: { host: "servidor" } }));

const { consultar, transaccion } = require("./conexion");

beforeEach(() => {
  mockQuery.mockReset();
  mockConnect.mockReset();
});

describe("Conexion a la base de datos", () => {
  test("el pool se crea con la configuracion del entorno", () => {
    expect(mockPool).toHaveBeenCalledWith({ host: "servidor" });
  });

  test("consultar ejecuta la consulta con sus parametros", async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 1 }] });

    const resultado = await consultar("SELECT $1", [1]);

    expect(mockQuery).toHaveBeenCalledWith("SELECT $1", [1]);
    expect(resultado.rows).toEqual([{ id: 1 }]);
  });

  test("consultar sin parametros usa una lista vacia", async () => {
    mockQuery.mockResolvedValue({ rows: [] });

    await consultar("SELECT 1");

    expect(mockQuery).toHaveBeenCalledWith("SELECT 1", []);
  });

  test("una transaccion exitosa hace COMMIT y libera el cliente", async () => {
    const cliente = { query: jest.fn().mockResolvedValue({}), release: jest.fn() };
    mockConnect.mockResolvedValue(cliente);

    const resultado = await transaccion(async (consulta) => {
      await consulta("INSERT 1", ["a"]);
      await consulta("INSERT 2");
      return "listo";
    });

    expect(resultado).toBe("listo");
    expect(cliente.query.mock.calls.map((c) => c[0])).toEqual(["BEGIN", "INSERT 1", "INSERT 2", "COMMIT"]);
    expect(cliente.query).toHaveBeenCalledWith("INSERT 2", []);
    expect(cliente.release).toHaveBeenCalledTimes(1);
  });

  test("una transaccion que falla hace ROLLBACK, lanza el error y libera el cliente", async () => {
    const cliente = { query: jest.fn().mockResolvedValue({}), release: jest.fn() };
    mockConnect.mockResolvedValue(cliente);

    await expect(
      transaccion(async () => {
        throw new Error("fallo");
      }),
    ).rejects.toThrow("fallo");

    expect(cliente.query.mock.calls.map((c) => c[0])).toEqual(["BEGIN", "ROLLBACK"]);
    expect(cliente.release).toHaveBeenCalledTimes(1);
  });
});
