const { Op } = require("sequelize");

jest.mock("../database/sequelize", () => ({
  sequelize: {
    transaction: jest.fn(async (accion) => accion("transaccion-falsa")),
  },
  models: {
    publicaciones: { findByPk: jest.fn(), findAll: jest.fn() },
    historial: { create: jest.fn() },
    usuarios: {},
  },
}));

const { models } = require("../database/sequelize");
const { putIntercambio, getIntercambios } = require("./intercambios.controlador");

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
    id_usuario_reserva: 2,
    titulo: "Calculadora",
    categoria: "electronica",
    estado_publicacion: "reservado",
    update: jest.fn().mockResolvedValue(),
    reload: jest.fn().mockResolvedValue(),
    ...datos,
  };
}

let consolaLog;
let consolaError;

beforeEach(() => {
  jest.clearAllMocks();
  consolaLog = jest.spyOn(console, "log").mockImplementation(() => {});
  consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consolaLog.mockRestore();
  consolaError.mockRestore();
});

describe("Completar un intercambio", () => {
  async function completar(idUsuario, id = "5") {
    const res = crearRespuesta();
    await putIntercambio({ usuario: { id: idUsuario }, params: { id } }, res);
    return res;
  }

  test.each([["abc"], ["0"], ["-3"], ["1.5"]])("el id %p no valido responde 400", async (id) => {
    const res = await completar(1, id);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.publicaciones.findByPk).not.toHaveBeenCalled();
  });

  test("una publicacion que no existe responde 404", async () => {
    models.publicaciones.findByPk.mockResolvedValue(null);

    const res = await completar(1);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("una persona ajena no puede completar y no se guarda nada", async () => {
    const publicacion = crearPublicacion();
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await completar(9);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(publicacion.update).not.toHaveBeenCalled();
    expect(models.historial.create).not.toHaveBeenCalled();
  });

  test("el dueno completa y el evento guarda a quien reservo como otra parte", async () => {
    const publicacion = crearPublicacion();
    models.publicaciones.findByPk.mockResolvedValue(publicacion);

    const res = await completar(1);

    expect(publicacion.update).toHaveBeenCalledWith(
      { estado_publicacion: "intercambiado" },
      { transaction: "transaccion-falsa" },
    );
    expect(models.historial.create).toHaveBeenCalledWith(
      {
        tipo: "completo",
        id_publicacion: 5,
        titulo: "Calculadora",
        categoria: "electronica",
        id_usuario: 1,
        id_otro_usuario: 2,
      },
      { transaction: "transaccion-falsa" },
    );
    expect(publicacion.reload).toHaveBeenCalled();
    expect(res.json).toHaveBeenCalledWith({
      publicacion,
      mensaje: "Intercambio completado correctamente",
    });
  });

  test("quien reservo completa y la otra parte es el dueno", async () => {
    models.publicaciones.findByPk.mockResolvedValue(crearPublicacion());

    await completar(2);

    expect(models.historial.create.mock.calls[0][0]).toEqual(
      expect.objectContaining({ id_usuario: 2, id_otro_usuario: 1 }),
    );
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findByPk.mockRejectedValue(new Error("caida"));

    const res = await completar(1);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("Ver intercambios completados", () => {
  test("pide las publicaciones intercambiadas donde participa la persona", async () => {
    models.publicaciones.findAll.mockResolvedValue([{ id: 5 }]);
    const res = crearRespuesta();

    await getIntercambios({ usuario: { id: 7 } }, res);

    const consulta = models.publicaciones.findAll.mock.calls[0][0];
    expect(consulta.where).toEqual({
      estado_publicacion: "intercambiado",
      [Op.or]: [{ id_usuario: 7 }, { id_usuario_reserva: 7 }],
    });
    expect(consulta.order).toEqual([["id", "DESC"]]);
    expect(res.json).toHaveBeenCalledWith([{ id: 5 }]);
  });

  test("un fallo inesperado responde 500", async () => {
    models.publicaciones.findAll.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await getIntercambios({ usuario: { id: 7 } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
