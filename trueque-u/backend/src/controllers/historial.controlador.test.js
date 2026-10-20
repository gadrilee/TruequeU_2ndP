const { Op } = require("sequelize");

// Se reemplaza la base de datos por una falsa: así la prueba no necesita conexión
jest.mock("../database/sequelize", () => ({
  models: {
    historial: { findAll: jest.fn() },
    usuarios: {},
  },
}));

const { models } = require("../database/sequelize");
const { getHistorial } = require("./historial.controlador");

// Un evento falso como los que devuelve la base de datos.
// Ana (1) es la dueña y Beto (2) reservó.
function crearEvento(datos) {
  return {
    id: 1,
    tipo: "reservo",
    id_publicacion: 5,
    titulo: "Calculadora",
    categoria: "electronica",
    id_usuario: 2, // quien hizo la acción: Beto
    id_otro_usuario: 1, // la otra parte: Ana
    creado_en: new Date("2026-10-20T15:00:00Z"),
    quien_hizo: { id: 2, nombre: "Beto" },
    la_otra_parte: { id: 1, nombre: "Ana" },
    ...datos,
  };
}

// Respuesta falsa de Express para poder ver qué devolvió el controlador
function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe("Historial de intercambios", () => {
  beforeEach(() => {
    models.historial.findAll.mockReset();
  });

  test("pide solo los eventos donde participó la persona, del más reciente al más antiguo", async () => {
    models.historial.findAll.mockResolvedValue([]);

    await getHistorial({ usuario: { id: 7 }, query: {} }, crearRespuesta());

    const consulta = models.historial.findAll.mock.calls[0][0];
    expect(consulta.where).toEqual({
      [Op.or]: [{ id_usuario: 7 }, { id_otro_usuario: 7 }],
    });
    expect(consulta.order).toEqual([
      ["creado_en", "DESC"],
      ["id", "DESC"],
    ]);
  });

  test("sin eventos devuelve una lista vacía", async () => {
    models.historial.findAll.mockResolvedValue([]);

    const res = crearRespuesta();
    await getHistorial({ usuario: { id: 1 }, query: {} }, res);

    expect(res.json).toHaveBeenCalledWith([]);
  });

  describe("cómo ve cada persona el mismo evento", () => {
    async function verComo(idUsuario) {
      models.historial.findAll.mockResolvedValue([crearEvento()]);
      const res = crearRespuesta();
      await getHistorial({ usuario: { id: idUsuario }, query: {} }, res);
      return res.json.mock.calls[0][0][0];
    }

    test("quien hizo la acción ve que la hizo él y al dueño como la otra persona", async () => {
      const evento = await verComo(2);
      expect(evento.lo_hice_yo).toBe(true);
      expect(evento.otra_persona).toEqual({ id: 1, nombre: "Ana" });
    });

    test("la otra parte ve quién hizo la acción", async () => {
      const evento = await verComo(1);
      expect(evento.lo_hice_yo).toBe(false);
      expect(evento.otra_persona).toEqual({ id: 2, nombre: "Beto" });
    });

    test("devuelve qué ocurrió, cuándo y sobre qué objeto, sin datos de contacto", async () => {
      const evento = await verComo(1);
      expect(evento.tipo).toBe("reservo");
      expect(evento.creado_en).toEqual(new Date("2026-10-20T15:00:00Z"));
      expect(evento.publicacion).toEqual({
        id: 5,
        titulo: "Calculadora",
        categoria: "electronica",
      });
      expect(JSON.stringify(evento)).not.toContain("telefono");
    });
  });

  describe("filtro por tipo", () => {
    beforeEach(() => {
      models.historial.findAll.mockResolvedValue([]);
    });

    test("reservas trae las reservas y las cancelaciones", async () => {
      await getHistorial({ usuario: { id: 1 }, query: { tipo: "reservas" } }, crearRespuesta());

      const consulta = models.historial.findAll.mock.calls[0][0];
      expect(consulta.where.tipo).toEqual({ [Op.in]: ["reservo", "cancelo_reserva"] });
    });

    test("completados trae solo los intercambios completados", async () => {
      await getHistorial({ usuario: { id: 1 }, query: { tipo: "completados" } }, crearRespuesta());

      const consulta = models.historial.findAll.mock.calls[0][0];
      expect(consulta.where.tipo).toBe("completo");
    });

    test("un tipo que no existe da error 400 y no consulta la base", async () => {
      const res = crearRespuesta();
      await getHistorial({ usuario: { id: 1 }, query: { tipo: "loquesea" } }, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(models.historial.findAll).not.toHaveBeenCalled();
    });
  });
});
