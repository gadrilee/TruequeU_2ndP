const { Sequelize } = require("sequelize");
const { baseDeDatos } = require("../configuration/entorno");
const initModels = require("../models/init-models");

// Crea la conexión con la base de datos (los datos salen del .env)
function crearConexion() {
  const { connectionString, host, port, database, user, password } = baseDeDatos;

  // Base en línea (Neon): se usa la cadena de conexión.
  // Si la cadena trae sslmode (Neon la trae), se conecta con SSL.
  if (connectionString) {
    const sinParametros = connectionString.replace(/\?.*$/, "");
    const usaSsl = connectionString.includes("sslmode=");
    return new Sequelize(sinParametros, {
      dialect: "postgres",
      logging: false,
      dialectOptions: usaSsl ? { ssl: true } : {},
    });
  }

  // PostgreSQL instalado en tu computador.
  return new Sequelize(database, user, password, {
    host,
    port,
    dialect: "postgres",
    logging: false,
  });
}

const sequelize = crearConexion();

// Carga los modelos que generó sequelize-auto (carpeta src/models)
const models = initModels(sequelize);

// Relaciones con nombres cortos: la app lee "autor" y "usuario_reserva"
models.publicaciones.belongsTo(models.usuarios, {
  as: "autor", // quien creó la publicación
  foreignKey: "id_usuario",
});
models.publicaciones.belongsTo(models.usuarios, {
  as: "usuario_reserva", // quien la reservó (puede ser null)
  foreignKey: "id_usuario_reserva",
});

// Historial: quién hizo la acción y quién es la otra parte del intercambio
models.historial.belongsTo(models.usuarios, {
  as: "quien_hizo",
  foreignKey: "id_usuario",
});
models.historial.belongsTo(models.usuarios, {
  as: "la_otra_parte",
  foreignKey: "id_otro_usuario",
});

models.ofertas.belongsTo(models.publicaciones, {
  as: "pedida",
  foreignKey: "id_publicacion_pedida",
});
models.ofertas.belongsTo(models.publicaciones, {
  as: "ofrecida",
  foreignKey: "id_publicacion_ofrecida",
});
models.ofertas.belongsTo(models.usuarios, {
  as: "oferente",
  foreignKey: "id_usuario",
});

// Se usa así: const { models } = require("../database/sequelize");
//             models.publicaciones.findAll(), models.usuarios.findByPk(1), etc.
module.exports = { sequelize, models };
