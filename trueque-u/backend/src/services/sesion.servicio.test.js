jest.mock("../database/sequelize", () => ({
  models: { sesiones: { create: jest.fn() } },
}));
jest.mock("../configuration/entorno", () => ({ duracionSesionDias: 7 }));

const { models } = require("../database/sequelize");
const { crearSesion } = require("./sesion.servicio");

beforeEach(() => {
  jest.clearAllMocks();
  jest.useFakeTimers().setSystemTime(new Date("2026-01-01T00:00:00Z"));
  models.sesiones.create.mockResolvedValue({ id: "sesion-1" });
});

afterEach(() => {
  jest.useRealTimers();
});

describe("Crear sesion", () => {
  test("crea la sesion con vencimiento a siete dias y devuelve su id", async () => {
    const transaccion = { id: "tx" };

    const id = await crearSesion(3, transaccion);

    expect(id).toBe("sesion-1");
    expect(models.sesiones.create).toHaveBeenCalledWith(
      { usuario_id: 3, expira_en: new Date("2026-01-08T00:00:00Z") },
      { transaction: transaccion },
    );
  });
});
