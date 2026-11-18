jest.mock("../database/sequelize", () => ({ models: {}, sequelize: { literal: jest.fn() } }));
jest.mock("../middleware/autenticacion.middleware", () => ({ exigirSesion: jest.fn() }));
jest.mock("../controllers/calificaciones.controlador");
jest.mock("../controllers/cuenta.controlador");
jest.mock("../controllers/eventos.controlador");
jest.mock("../controllers/historial.controlador");
jest.mock("../controllers/intercambios.controlador");
jest.mock("../controllers/misDatos.controlador");
jest.mock("../controllers/notificaciones.controlador");
jest.mock("../controllers/ofertas.controlador");
jest.mock("../controllers/propuestasEntrega.controlador");
jest.mock("../controllers/publicaciones.controlador");
jest.mock("../controllers/recuperaciones.controlador");
jest.mock("../controllers/reservas.controlador");
jest.mock("../controllers/sesiones.controlador");
jest.mock("../controllers/usuarios.controlador");

const { exigirSesion } = require("../middleware/autenticacion.middleware");
const calificaciones = require("../controllers/calificaciones.controlador");
const cuenta = require("../controllers/cuenta.controlador");
const eventos = require("../controllers/eventos.controlador");
const historial = require("../controllers/historial.controlador");
const intercambios = require("../controllers/intercambios.controlador");
const misDatos = require("../controllers/misDatos.controlador");
const notificaciones = require("../controllers/notificaciones.controlador");
const ofertas = require("../controllers/ofertas.controlador");
const propuestasEntrega = require("../controllers/propuestasEntrega.controlador");
const publicaciones = require("../controllers/publicaciones.controlador");
const recuperaciones = require("../controllers/recuperaciones.controlador");
const reservas = require("../controllers/reservas.controlador");
const sesiones = require("../controllers/sesiones.controlador");
const usuarios = require("../controllers/usuarios.controlador");

function listarRutas(router) {
  return router.stack
    .filter((capa) => capa.route)
    .map((capa) => ({
      metodo: Object.keys(capa.route.methods)[0].toUpperCase(),
      ruta: capa.route.path,
      manejadores: capa.route.stack.map((c) => c.handle),
    }));
}

function comprobarRutas(router, esperadas) {
  const reales = listarRutas(router);
  expect(reales.map((r) => `${r.metodo} ${r.ruta}`)).toEqual(
    esperadas.map(([metodo, ruta]) => `${metodo} ${ruta}`),
  );
  esperadas.forEach(([, , controlador, publica], i) => {
    const esperado = publica ? [controlador] : [exigirSesion, controlador];
    expect(reales[i].manejadores).toEqual(esperado);
  });
}

describe("Rutas de calificaciones", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./calificaciones.rutas"), [
      ["GET", "/", calificaciones.getMiCalificacion],
      ["POST", "/", calificaciones.postCalificacion],
      ["GET", "/resumen", calificaciones.getResumenCalificaciones],
    ]);
  });
});

describe("Rutas de eventos", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./eventos.rutas"), [
      ["POST", "/eventos", eventos.postEvento],
      ["GET", "/analitica", eventos.getAnalitica],
    ]);
  });
});

describe("Rutas de historial", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./historial.rutas"), [["GET", "/", historial.getHistorial]]);
  });
});

describe("Rutas de intercambios", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./intercambios.rutas"), [
      ["GET", "/intercambiadas", intercambios.getIntercambios],
      ["PUT", "/:id/intercambiado", intercambios.putIntercambio],
    ]);
  });
});

describe("Rutas de notificaciones", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./notificaciones.rutas"), [
      ["GET", "/", notificaciones.getNotificaciones],
      ["PUT", "/:id/leida", notificaciones.putNotificacionLeida],
    ]);
  });
});

describe("Rutas de ofertas", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./ofertas.rutas"), [
      ["GET", "/recibidas", ofertas.getOfertasRecibidas],
      ["GET", "/enviadas", ofertas.getOfertasEnviadas],
      ["POST", "/", ofertas.postOferta],
      ["POST", "/:id/contraoferta", ofertas.postContraoferta],
      ["GET", "/:id/historial", ofertas.getHistorialOferta],
      ["PUT", "/:id/aceptada", ofertas.putOfertaAceptada],
      ["PUT", "/:id/rechazada", ofertas.putOfertaRechazada],
      ["PUT", "/:id/cancelada", ofertas.putOfertaCancelada],
      ["PUT", "/:id/entrega", ofertas.putOfertaEntrega],
      ["PUT", "/:id/anulada", ofertas.putOfertaAnulada],
    ]);
  });
});

describe("Rutas de propuestas de entrega", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./propuestasEntrega.rutas"), [
      ["GET", "/", propuestasEntrega.getPropuestasEntrega],
      ["POST", "/", propuestasEntrega.postPropuestaEntrega],
      ["POST", "/:id/contrapropuesta", propuestasEntrega.postContrapropuestaEntrega],
      ["PUT", "/:id/aceptada", propuestasEntrega.putPropuestaEntregaAceptada],
    ]);
  });
});

describe("Rutas de publicaciones", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./publicaciones.rutas"), [
      ["GET", "/", publicaciones.getPublicaciones],
      ["GET", "/mias", publicaciones.getMisPublicaciones],
      ["GET", "/:id", publicaciones.getPublicacion],
      ["POST", "/", publicaciones.postPublicacion],
      ["PUT", "/:id", publicaciones.putPublicacion],
      ["DELETE", "/:id", publicaciones.deletePublicacion],
      ["PUT", "/:id/oculto", publicaciones.putPublicacionOculto],
      ["PUT", "/:id/no-disponible", publicaciones.putPublicacionNoDisponible],
    ]);
  });
});

describe("Rutas de recuperaciones", () => {
  test("la recuperacion es publica", () => {
    comprobarRutas(require("./recuperaciones.rutas"), [
      ["POST", "/", recuperaciones.postRecuperacion, true],
    ]);
  });
});

describe("Rutas de reservas", () => {
  test("cada ruta usa su controlador con sesion", () => {
    comprobarRutas(require("./reservas.rutas"), [
      ["PUT", "/:id/reservado", reservas.putReserva],
      ["PUT", "/:id/disponible", reservas.putReservaDescartada],
    ]);
  });
});

describe("Rutas de sesiones", () => {
  test("iniciar sesion es publico y el resto exige sesion", () => {
    comprobarRutas(require("./sesiones.rutas"), [
      ["POST", "/", sesiones.postSesion, true],
      ["GET", "/actual", sesiones.getSesionActual],
      ["DELETE", "/actual", sesiones.deleteSesion],
    ]);
  });
});

describe("Rutas de usuarios", () => {
  test("registrarse es publico y el resto exige sesion", () => {
    comprobarRutas(require("./usuarios.rutas"), [
      ["POST", "/", usuarios.postUsuario, true],
      ["PUT", "/contrasena", usuarios.putContrasena],
      ["GET", "/yo/datos", misDatos.getMisDatos],
      ["DELETE", "/yo", cuenta.deleteCuenta],
      ["DELETE", "/yo/telefono", misDatos.deleteTelefono],
    ]);
  });
});

describe("Rutas principales", () => {
  test("cada grupo de rutas cuelga de su prefijo y en el orden correcto", () => {
    const principal = require("./index");

    expect(principal.stack).toHaveLength(12);
    const origen = principal.stack.map((capa) => capa.handle);
    expect(origen[3]).toBe(require("./intercambios.rutas"));
    expect(origen[4]).toBe(require("./publicaciones.rutas"));
    expect(origen[5]).toBe(require("./reservas.rutas"));
    expect(origen[0]).toBe(require("./usuarios.rutas"));
    expect(origen[11]).toBe(require("./eventos.rutas"));
  });
});
