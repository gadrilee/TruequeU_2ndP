jest.mock("../database/sequelize", () => ({
  sequelize: {
    literal: jest.fn((texto) => texto),
    transaction: jest.fn((funcion) => funcion({ LOCK: { UPDATE: "UPDATE" } })),
  },
  models: {
    usuarios: {},
    historial: {},
    publicaciones: { findByPk: jest.fn() },
    ofertas: {
      findByPk: jest.fn(),
      findAll: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
    },
  },
}));

const { models } = require("../database/sequelize");
const { postContraoferta, getHistorialOferta } = require("./ofertas.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

const pedida = { id: 1, id_usuario: 1, estado_publicacion: "disponible" };
const mouse = { id: 8, id_usuario: 3, estado_publicacion: "disponible" };
const mandil = { id: 7, id_usuario: 3, estado_publicacion: "disponible" };

function crearOferta(datos) {
  const oferta = {
    id: 1,
    id_publicacion_pedida: 1,
    id_publicacion_ofrecida: 8,
    id_usuario: 3,
    id_negociacion: 1,
    estado: "pendiente",
    ...datos,
  };
  oferta.update = jest.fn().mockResolvedValue(oferta);
  oferta.reload = jest.fn().mockResolvedValue(oferta);
  oferta.toJSON = () => ({ ...oferta });
  return oferta;
}

function publicacionesFalsas() {
  const filas = { 1: pedida, 7: mandil, 8: mouse };
  models.publicaciones.findByPk.mockImplementation(async (id) => filas[id] || null);
}

describe("Contraoferta", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    models.ofertas.count.mockResolvedValue(0);
    publicacionesFalsas();
  });

  test("la dueña responde la oferta de Carlos con otro objeto y la anterior queda contraofertada", async () => {
    const oferta = crearOferta();
    const nueva = crearOferta({ id: 2, id_usuario: 1, id_publicacion_ofrecida: 7 });
    models.ofertas.findByPk.mockResolvedValue(oferta);
    models.ofertas.create.mockResolvedValue(nueva);

    const req = { usuario: { id: 1 }, params: { id: "1" }, body: { id_publicacion_ofrecida: 7 } };
    const res = crearRespuesta();
    await postContraoferta(req, res);

    expect(oferta.update).toHaveBeenCalledWith({ estado: "contraofertada" }, expect.anything());
    const datos = models.ofertas.create.mock.calls[0][0];
    expect(datos.id_usuario).toBe(1);
    expect(datos.id_publicacion_pedida).toBe(1);
    expect(datos.id_publicacion_ofrecida).toBe(7);
    expect(datos.id_negociacion).toBe(1);
    expect(datos.id_oferta_anterior).toBe(1);
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test("Carlos no puede contraofertar su propia oferta", async () => {
    models.ofertas.findByPk.mockResolvedValue(crearOferta());

    const req = { usuario: { id: 3 }, params: { id: "1" }, body: { id_publicacion_ofrecida: 7 } };
    const res = crearRespuesta();
    await postContraoferta(req, res);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(models.ofertas.create).not.toHaveBeenCalled();
  });

  test("no se contraoferta una negociación que ya se cerró", async () => {
    models.ofertas.findByPk.mockResolvedValue(crearOferta({ estado: "aceptada" }));

    const req = { usuario: { id: 1 }, params: { id: "1" }, body: { id_publicacion_ofrecida: 7 } };
    const res = crearRespuesta();
    await postContraoferta(req, res);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.ofertas.create).not.toHaveBeenCalled();
  });

  test("pide el objeto de la contraoferta", async () => {
    const req = { usuario: { id: 1 }, params: { id: "1" }, body: {} };
    const res = crearRespuesta();
    await postContraoferta(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

describe("Historial de la negociación", () => {
  function propuestaFalsa(datos) {
    const propuesta = { pedida, ofrecida: mouse, ...datos };
    propuesta.toJSON = () => ({ ...propuesta });
    return propuesta;
  }

  beforeEach(() => {
    jest.clearAllMocks();
    models.ofertas.findByPk.mockResolvedValue(crearOferta());
    models.ofertas.findAll.mockResolvedValue([
      propuestaFalsa({ id: 1, estado: "contraofertada" }),
      propuestaFalsa({ id: 2, estado: "pendiente", ofrecida: mandil }),
    ]);
  });

  test("Carlos ve todas las propuestas en orden con su ronda", async () => {
    const req = { usuario: { id: 3 }, params: { id: "1" } };
    const res = crearRespuesta();
    await getHistorialOferta(req, res);

    const cuerpo = res.json.mock.calls[0][0];
    expect(cuerpo.abierta).toBe(true);
    expect(cuerpo.propuestas.map((p) => p.ronda)).toEqual([1, 2]);
  });

  test("la dueña también ve el historial", async () => {
    const req = { usuario: { id: 1 }, params: { id: "1" } };
    const res = crearRespuesta();
    await getHistorialOferta(req, res);

    expect(res.json.mock.calls[0][0].propuestas).toHaveLength(2);
  });

  test("una tercera persona recibe 403", async () => {
    const req = { usuario: { id: 2 }, params: { id: "1" } };
    const res = crearRespuesta();
    await getHistorialOferta(req, res);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  test("una negociación con la última propuesta aceptada ya no está abierta", async () => {
    models.ofertas.findAll.mockResolvedValue([
      propuestaFalsa({ id: 1, estado: "contraofertada" }),
      propuestaFalsa({ id: 2, estado: "aceptada" }),
    ]);
    const req = { usuario: { id: 1 }, params: { id: "1" } };
    const res = crearRespuesta();
    await getHistorialOferta(req, res);

    expect(res.json.mock.calls[0][0].abierta).toBe(false);
  });
});
