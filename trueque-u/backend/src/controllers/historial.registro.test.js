// Comprueba que reservar, cancelar y completar guarden su evento en el historial
// (y que una acción rechazada no guarde nada).

// Se reemplaza la base de datos por una falsa: así la prueba no necesita conexión
jest.mock("../database/sequelize", () => ({
  sequelize: {
    // La transacción falsa solo ejecuta lo que se le pasa
    transaction: jest.fn(async (accion) => accion("transaccion-falsa")),
  },
  models: {
    publicaciones: { findByPk: jest.fn() },
    historial: { create: jest.fn() },
    ofertas: { count: jest.fn() },
    usuarios: {},
  },
}));

const { models } = require("../database/sequelize");
const { putReserva, putReservaDescartada } = require("./reservas.controlador");
const { putIntercambio } = require("./intercambios.controlador");

// Una publicación falsa de Ana (1). Se pueden cambiar sus datos.
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

// Respuesta falsa de Express para poder ver qué devolvió el controlador
function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

// Pide la acción como la persona indicada
async function pedir(controlador, idUsuario, publicacion) {
  models.publicaciones.findByPk.mockResolvedValue(publicacion);
  const res = crearRespuesta();
  await controlador({ usuario: { id: idUsuario }, params: { id: "5" } }, res);
  return res;
}

beforeEach(() => {
  models.publicaciones.findByPk.mockReset();
  models.historial.create.mockReset();
  models.ofertas.count.mockReset();
  models.ofertas.count.mockResolvedValue(0);
});

describe("Reservar guarda el evento", () => {
  test("Beto reserva la publicación de Ana: se guarda 'reservo'", async () => {
    const res = await pedir(putReserva, 2, crearPublicacion());

    expect(res.status).not.toHaveBeenCalled();
    expect(models.historial.create).toHaveBeenCalledTimes(1);
    const [evento, opciones] = models.historial.create.mock.calls[0];
    expect(evento).toEqual({
      tipo: "reservo",
      id_publicacion: 5,
      titulo: "Calculadora",
      categoria: "electronica",
      id_usuario: 2, // quien reservó
      id_otro_usuario: 1, // la dueña
    });
    expect(opciones.transaction).toBe("transaccion-falsa");
  });

  test("el dueño no puede reservar lo suyo: no se guarda nada", async () => {
    const res = await pedir(putReserva, 1, crearPublicacion());

    expect(res.status).toHaveBeenCalledWith(403);
    expect(models.historial.create).not.toHaveBeenCalled();
  });

  test("una publicación ya reservada da error: no se guarda nada", async () => {
    const reservada = crearPublicacion({
      estado_publicacion: "reservado",
      id_usuario_reserva: 2,
    });
    const res = await pedir(putReserva, 3, reservada);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.historial.create).not.toHaveBeenCalled();
  });
});

describe("Cancelar la reserva guarda el evento", () => {
  test("Beto cancela su reserva: se guarda 'cancelo_reserva'", async () => {
    const reservada = crearPublicacion({
      estado_publicacion: "reservado",
      id_usuario_reserva: 2,
    });
    await pedir(putReservaDescartada, 2, reservada);

    expect(models.historial.create).toHaveBeenCalledTimes(1);
    const [evento] = models.historial.create.mock.calls[0];
    expect(evento.tipo).toBe("cancelo_reserva");
    expect(evento.id_usuario).toBe(2); // quien canceló
    expect(evento.id_otro_usuario).toBe(1); // la dueña
  });

  test("Ana reactiva una publicación oculta: no es una cancelación, no se guarda nada", async () => {
    const oculta = crearPublicacion({ estado_publicacion: "oculto" });
    const res = await pedir(putReservaDescartada, 1, oculta);

    expect(res.status).not.toHaveBeenCalled();
    expect(oculta.update).toHaveBeenCalled(); // sí cambia de estado
    expect(models.historial.create).not.toHaveBeenCalled();
  });

  test("Ana no puede cancelar la reserva de otra persona: no se guarda nada", async () => {
    const reservada = crearPublicacion({
      estado_publicacion: "reservado",
      id_usuario_reserva: 2,
    });
    const res = await pedir(putReservaDescartada, 1, reservada);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(models.historial.create).not.toHaveBeenCalled();
  });
});

describe("Completar el intercambio guarda el evento", () => {
  const reservada = () =>
    crearPublicacion({ estado_publicacion: "reservado", id_usuario_reserva: 2 });

  test("completa la dueña: la otra persona es quien reservó", async () => {
    await pedir(putIntercambio, 1, reservada());

    const [evento] = models.historial.create.mock.calls[0];
    expect(evento.tipo).toBe("completo");
    expect(evento.id_usuario).toBe(1);
    expect(evento.id_otro_usuario).toBe(2);
  });

  test("completa quien reservó: la otra persona es la dueña", async () => {
    await pedir(putIntercambio, 2, reservada());

    const [evento] = models.historial.create.mock.calls[0];
    expect(evento.tipo).toBe("completo");
    expect(evento.id_usuario).toBe(2);
    expect(evento.id_otro_usuario).toBe(1);
  });

  test("una publicación que no está reservada no se completa: no se guarda nada", async () => {
    const res = await pedir(putIntercambio, 1, crearPublicacion());

    expect(res.status).toHaveBeenCalledWith(409);
    expect(models.historial.create).not.toHaveBeenCalled();
  });

  test("un tercero no puede completar: no se guarda nada", async () => {
    const res = await pedir(putIntercambio, 3, reservada());

    expect(res.status).toHaveBeenCalledWith(403);
    expect(models.historial.create).not.toHaveBeenCalled();
  });
});
