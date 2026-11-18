const { Sequelize } = require("sequelize");
const initModels = require("./init-models");

describe("Modelos de la base de datos", () => {
  const sequelize = new Sequelize("postgres://u:p@localhost:5432/prueba", { logging: false });
  const models = initModels(sequelize);

  test("se crean los dieciocho modelos", () => {
    expect(Object.keys(models).sort()).toEqual([
      "account",
      "calificaciones",
      "eventos",
      "historial",
      "invitation",
      "jwks",
      "member",
      "notificaciones",
      "ofertas",
      "organization",
      "project_config",
      "propuestas_entrega",
      "publicaciones",
      "sesiones",
      "session",
      "user",
      "usuarios",
      "verification",
    ]);
  });

  test("cada modelo apunta a su tabla", () => {
    expect(models.usuarios.getTableName()).toMatchObject({ tableName: "usuarios", schema: "public" });
    expect(models.account.getTableName().schema).toBe("neon_auth");
  });

  test("las relaciones principales quedan definidas", () => {
    expect(models.usuarios.associations.publicaciones.foreignKey).toBe("id_usuario");
    expect(models.sesiones.associations.usuario.foreignKey).toBe("usuario_id");
    expect(models.propuestas_entrega.associations.oferta.foreignKey).toBe("id_oferta");
    expect(models.user.associations.accounts.foreignKey).toBe("userId");
  });

  test("las exportaciones alternativas son la misma funcion", () => {
    expect(initModels.initModels).toBe(initModels);
    expect(initModels.default).toBe(initModels);
  });
});
