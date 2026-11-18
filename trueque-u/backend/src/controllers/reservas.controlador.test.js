jest.mock("../database/sequelize", () => ({
  sequelize: {
    transaction: jest.fn(async (accion) => accion("transaccion-falsa")),
  },
  models: {
    publicaciones: { findByPk: jest.fn() },
    historial: { create: jest.fn() },
    usuarios: {},
  },
}));
jest.mock("../utils/ofertasPendientes", () => ({ estaEnOfertaPendiente: jest.fn() }));

const { models } = require("../database/sequelize");
const { estaEnOfertaPendiente } = require("../utils/ofertasPendientes");
const { putReserva, putReservaDescartada } = require("./reservas.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function crearPublicacion(datos) {
  return {
    id: 5,
    id_usuario: 1,
    id_usuario_reserva: null,
    titulo: "Calculadora",
    categoria: "electronica",
    estado_publicacion: "disponible",
    update: jest.fn().mockResolvedValue(),
    reload: jest.fn().mockResolvedValue(),
    ...datos,
  };
}

async function pedir(controlador, idUsuario, id = "5") {
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, params: { id } }, res);
  return res;
}

let consolaLog;
let consolaError;

beforeEach(() => {
  jest.clearAllMocks();
  estaEnOfertaPendiente.mockResolvedValue(false);
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consolaLog.mockRestore();
  consolaError.mockRestore();
});

describe("Reservar una publicacion", () => {
  test.each([["abc"], ["0"], ["2.5"]])("el id %p no valido responde 400", async (id) => {
    const res = await pedir(putReserva, 2, id);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una publicacion que no existe responde 404", async () => {
    models.publicaciones.findByPk.mockResolvedValue(null);

    const res = await pedir(putReserva, 2);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una publicacion ya reservada responde 409", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "reservado" }));

    const res = await pedir(putReserva, 2);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("el dueno no puede reservar su publicacion", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion());

    const res = await pedir(putReserva, 1);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("una publicacion intercambiada responde 409", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "intercambiado" }));

    const res = await pedir(putReserva, 2);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({ error: "La publicación ya fue intercambiada" });
  });

  test("una publicacion oculta responde 409", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "oculto" }));

    const res = await pedir(putReserva, 2);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({ error: "Solo se puede reservar una publicación disponible" });
  });

  test("una publicacion con oferta pendiente responde 409", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion());
    estaEnOfertaPendiente.mockResolvedValue(true);

    const res = await pedir(putReserva, 2);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.historial.create).not.toHaveBeenCalled();
  });

  test("reserva la publicacion y guarda el evento", async () => {
    const publicacion = crearPublicacion();
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(putReserva, 2);

    expect(publicacion.update).toHaveBeenCalledWith(
      { estado_publicacion: "reservado", id_usuario_reserva: 2 },
      { transaction: "transaccion-falsa" },
    );
    expect(models.historial.create.mock.calls[0][0]).toEqual(
      expect.objectContaining({ tipo: "reservo", id_usuario: 2, id_otro_usuario: 1 }),
    );
    expect(res.json).toHaveBeenCalledWith({ publicacion, mensaje: "Publicación reservada correctamente" });
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(putReserva, 2);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Descartar una reserva", () => {
  test.each([["abc"], ["-1"]])("el id %p no valido responde 400", async (id) => {
    const res = await pedir(putReservaDescartada, 2, id);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("una publicacion que no existe responde 404", async () => {
    models.publicaciones.findByPk.mockResolvedValue(null);

    const res = await pedir(putReservaDescartada, 2);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una publicacion intercambiada responde 409", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "intercambiado" }));

    const res = await pedir(putReservaDescartada, 1);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  test("una publicacion acordada responde 409", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "acordado" }));

    const res = await pedir(putReservaDescartada, 1);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json.mock.calls[0][0].error).toContain("intercambio acordado");
  });

  test("el dueno no puede descartar la reserva de otra persona", async () => {
    models.publicaciones.findByPk.mockResolvedValue(
      crearPublicacion({ estado_publicacion: "reservado", id_usuario_reserva: 2 }),
    );

    const res = await pedir(putReservaDescartada, 1);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("una persona ajena no puede liberar una publicacion oculta", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion({ estado_publicacion: "oculto" }));

    const res = await pedir(putReservaDescartada, 9);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("quien reservo descarta la reserva y se guarda la cancelacion", async () => {
    const publicacion = crearPublicacion({ estado_publicacion: "reservado", id_usuario_reserva: 2 });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await pedir(putReservaDescartada, 2);

    expect(publicacion.update).toHaveBeenCalledWith(
      { estado_publicacion: "disponible", id_usuario_reserva: null },
      { transaction: "transaccion-falsa" },
    );
    expect(models.historial.create.mock.calls[0][0]).toEqual(
      expect.objectContaining({ tipo: "cancelo_reserva", id_usuario: 2, id_otro_usuario: 1 }),
    );
    expect(res.json).toHaveBeenCalledWith({
      publicacion,
      mensaje: "Publicación ahora disponible para intercambio",
    });
  });

  test("el dueno reactiva una publicacion oculta sin guardar historial", async () => {
    const publicacion = crearPublicacion({ estado_publicacion: "oculto" });
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    await pedir(putReservaDescartada, 1);

    expect(publicacion.update).toHaveBeenCalled();
    expect(models.historial.create).not.toHaveBeenCalled();
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findByPk.mockRejectedValue(new Error("caida"));

    const res = await pedir(putReservaDescartada, 2);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
