const { Op } = require("sequelize");

// Se reemplaza la base de datos por una falsa: así la prueba no necesita conexión
jest.mock("../database/sequelize", () => ({
  models: {
    publicaciones: { findAll: jest.fn() },
    ofertas: { findAll: jest.fn() },
    usuarios: {},
  },
}));

const { models } = require("../database/sequelize");
const { getPublicaciones } = require("./publicaciones.controlador");

// Una fila falsa como las que devuelve la base de datos (con toJSON)
function crearFila(datos) {
  return { ...datos, toJSON: () => ({ ...datos }) };
}

// Respuesta falsa de Express para poder ver qué devolvió el controlador
function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

beforeEach(() => {
  models.ofertas.findAll.mockReset();
  models.ofertas.findAll.mockResolvedValue([]);
});

describe("Marcar las publicaciones con oferta enviada", () => {
  test("solo las que tienen una oferta pendiente mía llevan oferta_enviada", async () => {
    models.publicaciones.findAll.mockResolvedValue([
      crearFila({ id: 3, id_usuario: 1 }),
      crearFila({ id: 8, id_usuario: 3 }),
    ]);
    models.ofertas.findAll.mockResolvedValue([{ id_publicacion_pedida: 3 }]);

    const res = crearRespuesta();
    await getPublicaciones({ usuario: { id: 2 }, query: {} }, res);

    const lista = res.json.mock.calls[0][0];
    expect(lista[0].oferta_enviada).toBe(true);
    expect(lista[1].oferta_enviada).toBe(false);
    const consulta = models.ofertas.findAll.mock.calls[0][0];
    expect(consulta.where).toEqual({ id_usuario: 2, estado: "pendiente" });
  });
});

describe("Buscar y filtrar publicaciones", () => {
  beforeEach(() => {
    models.publicaciones.findAll.mockReset();
  });

  // CASO CON RESULTADOS: libros usados disponibles que tengan "algebra" en el título
  test("combina búsqueda y filtros y devuelve las publicaciones encontradas", async () => {
    const encontrada = { id: 1, titulo: "Libro de algebra", categoria: "libros" };
    models.publicaciones.findAll.mockResolvedValue([crearFila(encontrada)]);

    const req = {
      usuario: { id: 1 },
      query: {
        buscar: "algebra",
        categoria: "libros",
        condicion: "usado",
        disponibilidad: "disponible",
      },
    };
    const res = crearRespuesta();
    await getPublicaciones(req, res);

    // Lo que se le pidió a la base de datos
    const consulta = models.publicaciones.findAll.mock.calls[0][0];
    expect(consulta.where.titulo).toEqual({ [Op.iLike]: "%algebra%" });
    expect(consulta.where.categoria).toBe("libros");
    expect(consulta.where.estado).toBe("usado");
    expect(consulta.where.estado_publicacion).toBe("disponible");

    // Lo que se devolvió a la app
    const devueltas = res.json.mock.calls[0][0];
    expect(devueltas).toHaveLength(1);
    expect(devueltas[0].titulo).toBe(encontrada.titulo);
  });

  // CASO SIN RESULTADOS: ninguna publicación coincide
  test("si nada coincide devuelve una lista vacía", async () => {
    models.publicaciones.findAll.mockResolvedValue([]);

    const req = { usuario: { id: 1 }, query: { buscar: "no existe", categoria: "ropa" } };
    const res = crearRespuesta();
    await getPublicaciones(req, res);

    expect(res.json).toHaveBeenCalledWith([]);
  });

  test("sin filtros no muestra las ocultas ni las intercambiadas", async () => {
    models.publicaciones.findAll.mockResolvedValue([]);

    const res = crearRespuesta();
    await getPublicaciones({ usuario: { id: 1 }, query: {} }, res);

    const consulta = models.publicaciones.findAll.mock.calls[0][0];
    expect(consulta.where.estado_publicacion).toEqual({
      [Op.notIn]: ["oculto", "intercambiado"],
    });
  });

  test("una disponibilidad que no existe da error 400", async () => {
    const res = crearRespuesta();
    await getPublicaciones({ usuario: { id: 1 }, query: { disponibilidad: "loquesea" } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.publicaciones.findAll).not.toHaveBeenCalled();
  });

  // Privacidad: quién reservó solo lo ven el dueño y quien reservó
  describe("quién reservó", () => {
    // Publicación del usuario 1, reservada por el usuario 2
    const reservada = {
      id: 5,
      id_usuario: 1,
      id_usuario_reserva: 2,
      estado_publicacion: "reservado",
      usuario_reserva: { id: 2, nombre: "Reservador" },
    };

    async function verComo(idUsuario) {
      models.publicaciones.findAll.mockResolvedValue([crearFila(reservada)]);
      const res = crearRespuesta();
      await getPublicaciones({ usuario: { id: idUsuario }, query: {} }, res);
      return res.json.mock.calls[0][0][0];
    }

    test("el dueño ve quién reservó", async () => {
      const publicacion = await verComo(1);
      expect(publicacion.usuario_reserva.nombre).toBe("Reservador");
    });

    test("quien reservó se ve a sí mismo", async () => {
      const publicacion = await verComo(2);
      expect(publicacion.id_usuario_reserva).toBe(2);
    });

    test("un tercero solo ve que está reservada, sin saber quién", async () => {
      const publicacion = await verComo(3);
      expect(publicacion.estado_publicacion).toBe("reservado");
      expect(publicacion.usuario_reserva).toBeNull();
      expect(publicacion.id_usuario_reserva).toBeNull();
    });
  });
});

describe("Teléfono del dueño en el catálogo (H7)", () => {
  beforeEach(() => {
    models.publicaciones.findAll.mockReset();
  });

  // Publicación del usuario 1, reservada por el usuario 2
  const filaReservada = () =>
    crearFila({
      id: 7,
      id_usuario: 1,
      id_usuario_reserva: 2,
      estado_publicacion: "reservado",
      autor: { id: 1, nombre: "Ana", telefono: "70000000" },
      usuario_reserva: { id: 2, nombre: "Beto" },
    });

  async function pedirComo(idUsuario) {
    models.publicaciones.findAll.mockResolvedValue([filaReservada()]);
    const res = crearRespuesta();
    await getPublicaciones({ usuario: { id: idUsuario }, query: {} }, res);
    return res.json.mock.calls[0][0][0];
  }

  test("quien reservó recibe el teléfono del dueño", async () => {
    const pub = await pedirComo(2);
    expect(pub.autor.telefono).toBe("70000000");
  });

  test("otra persona no recibe el teléfono del dueño", async () => {
    const pub = await pedirComo(3);
    expect(pub.autor.telefono).toBeUndefined();
    expect(pub.autor.nombre).toBe("Ana");
  });
});
