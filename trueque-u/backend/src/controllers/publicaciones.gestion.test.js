const { Op } = require("sequelize");

jest.mock("../database/sequelize", () => ({
  models: {
    usuarios: {},
    publicaciones: { findAll: jest.fn(), findByPk: jest.fn(), create: jest.fn() },
    ofertas: { findAll: jest.fn() },
  },
}));
jest.mock("../services/imagenes", () => ({
  guardarImagen: jest.fn(),
  borrarImagen: jest.fn(),
}));
jest.mock("../utils/ofertasPendientes", () => ({ estaEnOfertaPendiente: jest.fn() }));

const { models } = require("../database/sequelize");
const { guardarImagen, borrarImagen } = require("../services/imagenes");
const { estaEnOfertaPendiente } = require("../utils/ofertasPendientes");
const {
  getPublicaciones,
  getMisPublicaciones,
  getPublicacion,
  postPublicacion,
  putPublicacion,
  deletePublicacion,
  putPublicacionOculto,
  putPublicacionNoDisponible,
} = require("./publicaciones.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function crearFila(datos) {
  return { ...datos, toJSON: () => ({ ...datos }) };
}

function crearPublicacion(datos) {
  return {
    id: 5,
    id_usuario: 1,
    id_usuario_reserva: null,
    estado_publicacion: "disponible",
    imagen_url: null,
    update: jest.fn().mockResolvedValue(),
    reload: jest.fn().mockResolvedValue(),
    destroy: jest.fn().mockResolvedValue(),
    toJSON() {
      return { id: this.id, id_usuario: this.id_usuario, id_usuario_reserva: this.id_usuario_reserva, usuario_reserva: { id: 2 } };
    },
    ...datos,
  };
}

async function pedir(controlador, idUsuario, { body, params = { id: "5" }, query = {} } = {}) {
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, params, body, query }, res);
  return res;
}

let consolaLog;
let consolaError;

beforeEach(() => {
  jest.clearAllMocks();
  models.ofertas.findAll.mockResolvedValue([]);
  estaEnOfertaPendiente.mockResolvedValue(false);
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consolaLog.mockRestore();
  consolaError.mockRestore();
});

describe("Catalogo: filtros", () => {
  beforeEach(() => {
    models.publicaciones.findAll.mockResolvedValue([]);
  });

  test("la busqueda escapa los comodines y ignora los espacios", async () => {
    await pedir(getPublicaciones, 1, { query: { buscar: "  50%_off\\ " } });

    const donde = models.publicaciones.findAll.mock.calls[0][0].where;
    expect(donde.titulo).toEqual({ [Op.iLike]: "%50\\%\\_off\\\\%" });
  });

  test("una busqueda vacia o que no es texto no filtra", async () => {
    await pedir(getPublicaciones, 1, { query: { buscar: "   ", categoria: "", condicion: "", disponibilidad: "" } });
    await pedir(getPublicaciones, 1, { query: { buscar: ["a"], categoria: ["libros"], condicion: ["usado"], disponibilidad: ["x"] } });

    for (const llamada of models.publicaciones.findAll.mock.calls) {
      expect(Object.keys(llamada[0].where)).toEqual(["estado_publicacion"]);
    }
  });

  test("una categoria que no existe responde 400", async () => {
    const res = await pedir(getPublicaciones, 1, { query: { categoria: "juguetes" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una condicion que no existe responde 400", async () => {
    const res = await pedir(getPublicaciones, 1, { query: { condicion: "roto" } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una publicacion sin autor se devuelve igual", async () => {
    models.publicaciones.findAll.mockResolvedValue([crearFila({ id: 1, id_usuario: 1, estado_publicacion: "disponible" })]);

    const res = await pedir(getPublicaciones, 1);

    expect(res.json.mock.calls[0][0][0].autor).toBeUndefined();
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findAll.mockRejectedValue(new Error("caida"));

    const res = await pedir(getPublicaciones, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Mis publicaciones: casos que faltan", () => {
  test("una publicacion sin reserva se devuelve tal cual", async () => {
    models.publicaciones.findAll.mockResolvedValue([crearFila({ id: 1, estado_publicacion: "disponible", usuario_reserva: null })]);

    const res = await pedir(getMisPublicaciones, 1);

    expect(res.json.mock.calls[0][0][0].usuario_reserva).toBeNull();
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findAll.mockRejectedValue(new Error("caida"));

    const res = await pedir(getMisPublicaciones, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Ver una publicacion", () => {
  test.each([["abc"], ["0"], ["1.5"]])("el id %p no valido responde 400", async (id) => {
    const res = await pedir(getPublicacion, 1, { params: { id } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una publicacion que no existe responde 404", async () => {
    models.publicaciones.findByPk.mockResolvedValue(null);

    const res = await pedir(getPublicacion, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una publicacion oculta de otra persona responde 404", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "oculto" }));

    const res = await pedir(getPublicacion, 2);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("el dueno ve su publicacion oculta con el telefono de quien reservo", async () => {
    const publicacion = crearPublicacion({ estado_publicacion: "oculto", id_usuario_reserva: 2 });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(getPublicacion, 1);

    expect(publicacion.reload).toHaveBeenCalled();
    expect(res.json.mock.calls[0][0].usuario_reserva).toEqual({ id: 2 });
  });

  test("quien reservo ve la reserva", async () => {
    const publicacion = crearPublicacion({ id_usuario_reserva: 2 });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(getPublicacion, 2);

    expect(publicacion.reload).not.toHaveBeenCalled();
    expect(res.json.mock.calls[0][0].id_usuario_reserva).toBe(2);
  });

  test("un tercero no ve quien reservo", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ id_usuario_reserva: 2 }));

    const res = await pedir(getPublicacion, 3);

    const datos = res.json.mock.calls[0][0];
    expect(datos.id_usuario_reserva).toBeNull();
    expect(datos.usuario_reserva).toBeNull();
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(getPublicacion, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Crear una publicacion", () => {
  const cuerpo = { titulo: "  Calculo I ", descripcion: " Casi nuevo ", estado: "usado", categoria: "libros" };

  beforeEach(() => {
    models.publicaciones.create.mockResolvedValue({ id: 9 });
    models.publicaciones.findByPk.mockResolvedValue({ id: 9, titulo: "Calculo I" });
  });

  test.each([
    ["sin cuerpo", undefined, "Escribe un título (mínimo 2 letras)"],
    ["titulo que no es texto", { ...cuerpo, titulo: 3 }, "Escribe un título (mínimo 2 letras)"],
    ["titulo corto", { ...cuerpo, titulo: " a " }, "Escribe un título (mínimo 2 letras)"],
    ["titulo largo", { ...cuerpo, titulo: "a".repeat(151) }, "El título es muy largo (máximo 150)"],
    ["estado que no existe", { ...cuerpo, estado: "roto" }, "El estado debe ser nuevo o usado"],
    ["categoria que no existe", { ...cuerpo, categoria: "juguetes" }, "La categoría debe ser libros, electronica, ropa u otros"],
  ])("%s responde 400", async (nombre, body, error) => {
    const res = await pedir(postPublicacion, 1, { body });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error });
    expect(models.publicaciones.create).not.toHaveBeenCalled();
  });

  test("una foto invalida responde 400", async () => {
    guardarImagen.mockResolvedValue({ error: "La foto tiene que ser jpg o png" });

    const res = await pedir(postPublicacion, 1, { body: { ...cuerpo, imagen: "xxx" } });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: "La foto tiene que ser jpg o png" });
  });

  test("crea la publicacion con su foto", async () => {
    guardarImagen.mockResolvedValue({ url: "http://foto" });

    const res = await pedir(postPublicacion, 1, { body: { ...cuerpo, imagen: "datos" } });

    expect(models.publicaciones.create).toHaveBeenCalledWith({
      id_usuario: 1,
      titulo: "Calculo I",
      descripcion: "Casi nuevo",
      estado: "usado",
      categoria: "libros",
      imagen_url: "http://foto",
    });
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test("sin descripcion, categoria ni foto usa los valores por defecto", async () => {
    await pedir(postPublicacion, 1, { body: { titulo: "Mouse", estado: "nuevo", imagen: "   " } });

    expect(guardarImagen).not.toHaveBeenCalled();
    expect(models.publicaciones.create).toHaveBeenCalledWith({
      id_usuario: 1,
      titulo: "Mouse",
      descripcion: null,
      estado: "nuevo",
      categoria: "otros",
      imagen_url: null,
    });
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.create.mockRejectedValue(new Error("caida"));

    const res = await pedir(postPublicacion, 1, { body: cuerpo });

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Editar una publicacion", () => {
  let publicacion;

  beforeEach(() => {
    publicacion = crearPublicacion({ imagen_url: "http://vieja" });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);
  });

  test("actualiza solo los datos que llegan", async () => {
    const res = await pedir(putPublicacion, 1, {
      body: { titulo: " Nuevo ", descripcion: " Otra ", estado: "nuevo", categoria: "ropa" },
    });

    expect(publicacion.update).toHaveBeenCalledWith({
      titulo: "Nuevo",
      descripcion: "Otra",
      estado: "nuevo",
      categoria: "ropa",
    });
    expect(res.json).toHaveBeenCalledWith({ publicacion, mensaje: "Publicación actualizada correctamente" });
  });

  test("sin cuerpo no cambia nada pero responde bien", async () => {
    await pedir(putPublicacion, 1);

    expect(publicacion.update).toHaveBeenCalledWith({});
  });

  test("una descripcion que no es texto se guarda como null", async () => {
    await pedir(putPublicacion, 1, { body: { descripcion: 5 } });

    expect(publicacion.update).toHaveBeenCalledWith({ descripcion: null });
  });

  test("quitar_imagen borra la foto actual", async () => {
    await pedir(putPublicacion, 1, { body: { quitar_imagen: true } });

    expect(borrarImagen).toHaveBeenCalledWith("http://vieja");
    expect(publicacion.update).toHaveBeenCalledWith({ imagen_url: null });
  });

  test("una foto nueva reemplaza a la anterior", async () => {
    guardarImagen.mockResolvedValue({ url: "http://nueva" });

    await pedir(putPublicacion, 1, { body: { imagen: "datos" } });

    expect(borrarImagen).toHaveBeenCalledWith("http://vieja");
    expect(publicacion.update).toHaveBeenCalledWith({ imagen_url: "http://nueva" });
  });

  test("una foto invalida responde 400 y no borra la anterior", async () => {
    guardarImagen.mockResolvedValue({ error: "La foto puede pesar hasta 2 MB" });

    const res = await pedir(putPublicacion, 1, { body: { imagen: "datos" } });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(borrarImagen).not.toHaveBeenCalled();
  });

  test("una foto vacia no cambia la imagen", async () => {
    await pedir(putPublicacion, 1, { body: { imagen: "  " } });

    expect(guardarImagen).not.toHaveBeenCalled();
    expect(publicacion.update).toHaveBeenCalledWith({});
  });

  test.each([
    [{ titulo: 5 }],
    [{ titulo: "a" }],
    [{ titulo: "a".repeat(151) }],
    [{ estado: "roto" }],
    [{ categoria: "juguetes" }],
  ])("los datos %j no validos responden 400", async (body) => {
    const res = await pedir(putPublicacion, 1, { body });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(publicacion.update).not.toHaveBeenCalled();
  });
});

const ACCIONES = [
  ["Editar", putPublicacion, false],
  ["Eliminar", deletePublicacion, true],
  ["Ocultar", putPublicacionOculto, true],
  ["Marcar como no disponible", putPublicacionNoDisponible, true],
];

describe.each(ACCIONES)("%s una publicacion: reglas comunes", (nombre, controlador, revisaOfertas) => {
  test.each([["abc"], ["0"], ["-2"]])("el id %p no valido responde 400", async (id) => {
    const res = await pedir(controlador, 1, { params: { id } });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una publicacion que no existe responde 404", async () => {
    models.publicaciones.findByPk.mockResolvedValue(null);

    const res = await pedir(controlador, 1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una publicacion ajena responde 403", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion());

    const res = await pedir(controlador, 2);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test.each([["reservado"], ["intercambiado"], ["acordado"]])("una publicacion %s responde 409", async (estado) => {
    const publicacion = crearPublicacion({ estado_publicacion: estado });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(controlador, 1);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(publicacion.update).not.toHaveBeenCalled();
    expect(publicacion.destroy).not.toHaveBeenCalled();
  });

  if (revisaOfertas) {
    test("una publicacion con oferta pendiente responde 409", async () => {
      models.publicaciones.findByPk.mockResolvedValue(crearPublicacion());
      estaEnOfertaPendiente.mockResolvedValue(true);

      const res = await pedir(controlador, 1);

      expect(res.status).toHaveBeenCalledWith(409);
    });
  }

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(controlador, 1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Eliminar una publicacion", () => {
  test("borra la foto y la publicacion", async () => {
    const publicacion = crearPublicacion({ imagen_url: "http://foto" });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(deletePublicacion, 1);

    expect(borrarImagen).toHaveBeenCalledWith("http://foto");
    expect(publicacion.destroy).toHaveBeenCalled();
    expect(res.json).toHaveBeenCalledWith({ mensaje: "Publicación eliminada correctamente" });
  });
});

describe("Ocultar o marcar como no disponible", () => {
  test("ocultar deja la publicacion oculta y sin reserva", async () => {
    const publicacion = crearPublicacion();
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(putPublicacionOculto, 1);

    expect(publicacion.update).toHaveBeenCalledWith({ estado_publicacion: "oculto", id_usuario_reserva: null });
    expect(res.json).toHaveBeenCalledWith({ publicacion, mensaje: 'Publicación ahora está "oculto"' });
  });

  test("marcar como no disponible deja la publicacion sin reserva", async () => {
    const publicacion = crearPublicacion();
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(putPublicacionNoDisponible, 1);

    expect(publicacion.update).toHaveBeenCalledWith({ estado_publicacion: "no disponible", id_usuario_reserva: null });
    expect(res.json).toHaveBeenCalledWith({ publicacion, mensaje: 'Publicación ahora está "no disponible"' });
  });
});
