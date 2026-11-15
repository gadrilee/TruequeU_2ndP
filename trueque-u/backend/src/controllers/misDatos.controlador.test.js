jest.mock("../database/sequelize", () => ({
  models: {
    usuarios: { findByPk: jest.fn() },
    publicaciones: { findAll: jest.fn() },
    ofertas: { findAll: jest.fn() },
    calificaciones: { findAll: jest.fn() },
    historial: { findAll: jest.fn() },
  },
}));

const { models } = require("../database/sequelize");
const { getMisDatos } = require("./misDatos.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  res.setHeader = jest.fn();
  return res;
}

async function llamar(formato) {
  const res = crearRespuesta();
  await getMisDatos({ usuario: { id: 1 }, query: formato ? { formato } : {} }, res);
  return res;
}

beforeEach(() => {
  jest.clearAllMocks();
  models.usuarios.findByPk.mockResolvedValue({
    nombre: "Eudenia",
    correo: "eudenia@correo.com",
    telefono: "71234567",
    creado_en: new Date("2026-01-01T00:00:00Z"),
  });
  models.publicaciones.findAll.mockResolvedValue([
    { titulo: 'Libro, "Calculo"', descripcion: null, categoria: "libros", estado: "usado", estado_publicacion: "disponible" },
  ]);
  models.ofertas.findAll.mockResolvedValue([
    {
      estado: "pendiente",
      motivo_cancelacion: null,
      creado_en: new Date("2026-02-01T00:00:00Z"),
      pedida: { titulo: "Mouse" },
      ofrecida: { titulo: "Calculadora" },
    },
  ]);
  models.calificaciones.findAll.mockResolvedValue([
    { puntaje: 5, comentario: "Todo bien", creado_en: new Date("2026-03-01T00:00:00Z") },
  ]);
  models.historial.findAll.mockResolvedValue([]);
});

describe("Descarga de mis datos", () => {
  test("devuelve todo en json y como archivo adjunto", async () => {
    const res = await llamar("json");

    const datos = res.json.mock.calls[0][0];
    expect(datos.perfil.correo).toBe("eudenia@correo.com");
    expect(datos.publicaciones).toHaveLength(1);
    expect(datos.ofertas_hechas[0]).toMatchObject({ objeto_pedido: "Mouse", objeto_ofrecido: "Calculadora" });
    expect(datos.calificaciones_recibidas[0].puntaje).toBe(5);
    expect(res.setHeader).toHaveBeenCalledWith(
      "Content-Disposition",
      expect.stringContaining("attachment"),
    );
  });

  test("sin formato se usa json", async () => {
    const res = await llamar();

    expect(res.json).toHaveBeenCalled();
  });

  test("las calificaciones no traen datos de la otra persona", async () => {
    await llamar("json");

    const consulta = models.calificaciones.findAll.mock.calls[0][0];
    expect(consulta.attributes).toEqual(["puntaje", "comentario", "creado_en"]);
  });

  test("el csv trae las secciones y escapa las comillas", async () => {
    const res = await llamar("csv");

    const texto = res.send.mock.calls[0][0];
    expect(texto).toContain("perfil\nnombre,correo,telefono,creado_en");
    expect(texto).toContain('"Libro, ""Calculo"""');
    expect(texto).toContain("historial");
    expect(res.setHeader).toHaveBeenCalledWith("Content-Type", "text/csv; charset=utf-8");
  });

  test("un formato desconocido da error 400", async () => {
    const res = await llamar("xml");

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.usuarios.findByPk).not.toHaveBeenCalled();
  });

  test("si falla la base de datos responde 500", async () => {
    models.usuarios.findByPk.mockRejectedValue(new Error("falla"));
    jest.spyOn(console, "error").mockImplementation(() => {});

    const res = await llamar("json");

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
