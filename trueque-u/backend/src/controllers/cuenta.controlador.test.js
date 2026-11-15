jest.mock("../database/sequelize", () => ({
  sequelize: { transaction: jest.fn(async (funcion) => funcion({})) },
  models: {
    usuarios: { findByPk: jest.fn() },
    publicaciones: { findAll: jest.fn(), update: jest.fn() },
    ofertas: { findAll: jest.fn() },
    propuestas_entrega: { update: jest.fn() },
    notificaciones: { create: jest.fn() },
    sesiones: { update: jest.fn() },
    eventos: { create: jest.fn() },
  },
}));
jest.mock("../services/contrasena.servicio", () => ({
  coincide: jest.fn(),
}));

const { models } = require("../database/sequelize");
const { coincide } = require("../services/contrasena.servicio");
const { deleteCuenta } = require("./cuenta.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function crearOferta({ id, estado, pedida, ofrecida }) {
  return {
    id,
    estado,
    pedida,
    ofrecida,
    update: jest.fn().mockResolvedValue({}),
  };
}

function crearPublicacion(id, idUsuario, titulo) {
  return { id, id_usuario: idUsuario, titulo, update: jest.fn().mockResolvedValue({}) };
}

let usuario;

async function eliminar(contrasena = "eude1234") {
  const res = crearRespuesta();
  await deleteCuenta({ usuario: { id: 1 }, body: { contrasena } }, res);
  return res;
}

beforeEach(() => {
  jest.clearAllMocks();
  usuario = { id: 1, contrasena_hash: "hash", update: jest.fn().mockResolvedValue({}) };
  models.usuarios.findByPk.mockResolvedValue(usuario);
  models.publicaciones.findAll.mockResolvedValue([{ id: 10 }]);
  models.publicaciones.update.mockResolvedValue([1]);
  models.ofertas.findAll.mockResolvedValue([]);
  coincide.mockResolvedValue(true);
});

describe("Eliminar mi cuenta", () => {
  test("con la contraseña incorrecta responde 401 y no cambia nada", async () => {
    coincide.mockResolvedValue(false);

    const res = await eliminar("otra");

    expect(res.status).toHaveBeenCalledWith(401);
    expect(usuario.update).not.toHaveBeenCalled();
    expect(models.sesiones.update).not.toHaveBeenCalled();
  });

  test("sin contraseña responde 401", async () => {
    const res = crearRespuesta();

    await deleteCuenta({ usuario: { id: 1 }, body: {} }, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(usuario.update).not.toHaveBeenCalled();
  });

  test("anonimiza la cuenta y cierra todas las sesiones", async () => {
    const res = await eliminar();

    const cambios = usuario.update.mock.calls[0][0];
    expect(cambios.nombre).toBe("Usuario eliminado");
    expect(cambios.correo).toBe("eliminado-1@truequeu.local");
    expect(cambios.telefono).toBeNull();
    expect(cambios.eliminado_en).toBeInstanceOf(Date);
    expect(cambios.contrasena_hash).not.toBe("hash");
    expect(models.sesiones.update).toHaveBeenCalledWith(
      { cerrada_en: expect.any(Date) },
      expect.objectContaining({ where: { usuario_id: 1, cerrada_en: null } }),
    );
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ ok: true, trueques_cancelados: 0 }),
    );
  });

  test("oculta sus publicaciones y libera lo que tenia reservado", async () => {
    await eliminar();

    const llamadas = models.publicaciones.update.mock.calls;
    expect(llamadas[0][0]).toEqual({ estado_publicacion: "disponible", id_usuario_reserva: null });
    expect(llamadas[0][1].where).toMatchObject({ id_usuario_reserva: 1, estado_publicacion: "reservado" });
    expect(llamadas[1][0]).toEqual({ estado_publicacion: "oculto", id_usuario_reserva: null });
    expect(llamadas[1][1].where.id_usuario).toBe(1);
  });

  test("una oferta pendiente pasa a cancelada y avisa a la otra persona", async () => {
    const pedida = crearPublicacion(20, 2, "Mouse");
    const ofrecida = crearPublicacion(10, 1, "Calculadora");
    const oferta = crearOferta({ id: 5, estado: "pendiente", pedida, ofrecida });
    models.ofertas.findAll.mockResolvedValue([oferta]);

    const res = await eliminar();

    expect(oferta.update).toHaveBeenCalledWith({ estado: "cancelada" }, expect.anything());
    expect(pedida.update).not.toHaveBeenCalled();
    expect(models.notificaciones.create).toHaveBeenCalledWith(
      {
        id_usuario: 2,
        mensaje: 'Tu trueque por "Mouse" se canceló porque la otra persona eliminó su cuenta.',
      },
      expect.anything(),
    );
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ trueques_cancelados: 1 }));
  });

  test("un trueque acordado se anula con motivo y libera la publicacion de la otra persona", async () => {
    const pedida = crearPublicacion(10, 1, "Calculadora");
    const ofrecida = crearPublicacion(20, 2, "Mouse");
    const oferta = crearOferta({ id: 6, estado: "aceptada", pedida, ofrecida });
    models.ofertas.findAll.mockResolvedValue([oferta]);

    await eliminar();

    expect(oferta.update).toHaveBeenCalledWith(
      {
        estado: "anulada",
        motivo_cancelacion: "Cuenta del usuario eliminada",
        id_usuario_cancela: 1,
      },
      expect.anything(),
    );
    expect(ofrecida.update).toHaveBeenCalledWith(
      { estado_publicacion: "disponible", id_usuario_reserva: null },
      expect.anything(),
    );
    expect(pedida.update).not.toHaveBeenCalled();
    expect(models.propuestas_entrega.update).toHaveBeenCalledWith(
      { estado: "reemplazada" },
      expect.objectContaining({ where: expect.objectContaining({ id_oferta: expect.anything() }) }),
    );
    expect(models.notificaciones.create.mock.calls[0][0].id_usuario).toBe(2);
  });

  test("registra el evento cuenta_eliminada sin datos personales", async () => {
    await eliminar();

    expect(models.eventos.create).toHaveBeenCalledWith(
      { evento: "cuenta_eliminada", props: { trueques_cancelados: 0 } },
      expect.anything(),
    );
  });

  test("sin trueques acordados no toca las propuestas de entrega", async () => {
    await eliminar();

    expect(models.propuestas_entrega.update).not.toHaveBeenCalled();
    expect(models.notificaciones.create).not.toHaveBeenCalled();
  });

  test("si algo falla responde 500", async () => {
    models.publicaciones.findAll.mockRejectedValue(new Error("falla"));
    jest.spyOn(console, "error").mockImplementation(() => {});

    const res = await eliminar();

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
