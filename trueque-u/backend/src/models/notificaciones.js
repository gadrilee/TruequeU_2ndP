const Sequelize = require("sequelize");
module.exports = function (sequelize, DataTypes) {
  return sequelize.define(
    "notificaciones",
    {
      id: {
        autoIncrement: true,
        autoIncrementIdentity: true,
        type: DataTypes.INTEGER,
        allowNull: false,
        primaryKey: true,
      },
      id_usuario: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "usuarios", key: "id" },
      },
      mensaje: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
      leida: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      creado_en: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    },
    {
      sequelize,
      tableName: "notificaciones",
      schema: "public",
      timestamps: false,
    },
  );
};
