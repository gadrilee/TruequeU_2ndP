jest.mock("../database/sequelize", () => ({
  models: {
    ofertas: { findByPk: jest.fn() },
    publicaciones: { findByPk: jest.fn() },
  },
}));

const { models } = require("../database/sequelize");
const { cargarOferta } = require("./cargarOferta");

beforeEach(() => {
  jest.clearAllMocks();
});

describe("Cargar una oferta con sus publicaciones", () => {
  const oferta = { id: 1, id_publicacion_pedida: 10, id_publicacion_ofrecida: 20 };

  test("sin oferta devuelve 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(null);

    const resultado = await cargarOferta(1);

    expect(resultado).toEqual({ codigo: 404, error: "Oferta no encontrada" });
  });

  test("devuelve la oferta con las dos publicaciones", async () => {
    models.ofertas.findByPk.mockResolvedValue(oferta);
    models.publicaciones.findByPk.mockImplementation(async (id) => ({ id }));

    const resultado = await cargarOferta(1);

    expect(models.ofertas.findByPk).toHaveBeenCalledWith(1, {});
    expect(resultado).toEqual({ oferta, pedida: { id: 10 }, ofrecida: { id: 20 } });
  });

  test("con transaccion bloquea la oferta para actualizar", async () => {
    const transaction = { LOCK: { UPDATE: "UPDATE" } };
    models.ofertas.findByPk.mockResolvedValue(oferta);
    models.publicaciones.findByPk.mockImplementation(async (id) => ({ id }));

    await cargarOferta(1, transaction);

    expect(models.ofertas.findByPk).toHaveBeenCalledWith(1, { transaction, lock: "UPDATE" });
    expect(models.publicaciones.findByPk).toHaveBeenCalledWith(10, { transaction });
  });

  test("si falta la publicacion ofrecida devuelve 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(oferta);
    models.publicaciones.findByPk.mockResolvedValueOnce({ id: 10 }).mockResolvedValueOnce(null);

    const resultado = await cargarOferta(1);

    expect(resultado).toEqual({ codigo: 404, error: "Ya no existe alguna de las publicaciones" });
  });

  test("si falta la publicacion pedida devuelve 404", async () => {
    models.ofertas.findByPk.mockResolvedValue(oferta);
    models.publicaciones.findByPk.mockResolvedValueOnce(null).mockResolvedValueOnce({ id: 20 });

    const resultado = await cargarOferta(1);

    expect(resultado.codigo).toBe(404);
  });
});
