const Sequelize = require("sequelize");
module.exports = function (sequelize, DataTypes) {
  return sequelize.define(
    "ofertas",
    {
      id: {
        autoIncrement: true,
        autoIncrementIdentity: true,
        type: DataTypes.INTEGER,
        allowNull: false,
        primaryKey: true,
      },
      id_publicacion_pedida: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "publicaciones", key: "id" },
      },
      id_publicacion_ofrecida: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "publicaciones", key: "id" },
      },
      id_usuario: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "usuarios", key: "id" },
      },
      estado: {
        type: DataTypes.STRING(15),
        allowNull: false,
        defaultValue: "pendiente",
      },
      id_negociacion: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },
      id_oferta_anterior: {
        type: DataTypes.INTEGER,
        allowNull: true,
        references: { model: "ofertas", key: "id" },
      },
      creado_en: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    },
    {
      sequelize,
      tableName: "ofertas",
      schema: "public",
      timestamps: false,
    },
  );
};
