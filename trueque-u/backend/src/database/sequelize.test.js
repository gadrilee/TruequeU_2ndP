const mockEntorno = { baseDeDatos: {} };

jest.mock("../configuration/entorno", () => mockEntorno);

function cargarBase(baseDeDatos) {
  mockEntorno.baseDeDatos = baseDeDatos;
  let modulo;
  jest.isolateModules(() => {
    modulo = require("./sequelize");
  });
  return modulo;
}

describe("Conexion Sequelize", () => {
  test("con datos sueltos se conecta al servidor indicado", () => {
    const { sequelize } = cargarBase({
      host: "servidor",
      port: 5433,
      database: "mi_base",
      user: "yo",
      password: "secreta",
    });

    expect(sequelize.getDialect()).toBe("postgres");
    expect(sequelize.config).toEqual(
      expect.objectContaining({ host: "servidor", port: 5433, database: "mi_base", username: "yo" }),
    );
    expect(sequelize.options.dialectOptions).toBeUndefined();
  });

  test("con cadena de conexion con sslmode usa SSL", () => {
    const { sequelize } = cargarBase({
      connectionString: "postgres://u:p@host.neon.tech/db?sslmode=verify-full",
    });

    expect(sequelize.config.host).toBe("host.neon.tech");
    expect(sequelize.config.database).toBe("db");
    expect(sequelize.options.dialectOptions.ssl).toBe(true);
  });

  test("con cadena de conexion sin sslmode no usa SSL", () => {
    const { sequelize } = cargarBase({ connectionString: "postgres://u:p@host/db" });

    expect(sequelize.config.host).toBe("host");
    expect(sequelize.options.dialectOptions.ssl).toBeUndefined();
  });

  test("carga los modelos y las relaciones con nombres cortos", () => {
    const { models } = cargarBase({ host: "localhost", port: 5432, database: "d", user: "u", password: "p" });

    expect(Object.keys(models)).toHaveLength(18);
    expect(models.publicaciones.associations.autor.foreignKey).toBe("id_usuario");
    expect(models.publicaciones.associations.usuario_reserva.foreignKey).toBe("id_usuario_reserva");
    expect(models.historial.associations.quien_hizo.foreignKey).toBe("id_usuario");
    expect(models.historial.associations.la_otra_parte.foreignKey).toBe("id_otro_usuario");
    expect(models.ofertas.associations.pedida.foreignKey).toBe("id_publicacion_pedida");
    expect(models.ofertas.associations.ofrecida.foreignKey).toBe("id_publicacion_ofrecida");
    expect(models.ofertas.associations.oferente.foreignKey).toBe("id_usuario");
  });
});
