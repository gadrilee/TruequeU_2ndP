const Sequelize = require("sequelize");
module.exports = function (sequelize, DataTypes) {
  return sequelize.define(
    "propuestas_entrega",
    {
      id: {
        autoIncrement: true,
        autoIncrementIdentity: true,
        type: DataTypes.INTEGER,
        allowNull: false,
        primaryKey: true,
      },
      id_oferta: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "ofertas", key: "id" },
      },
      id_usuario: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "usuarios", key: "id" },
      },
      fecha: {
        type: DataTypes.DATEONLY,
        allowNull: false,
      },
      hora: {
        type: DataTypes.TIME,
        allowNull: false,
      },
      lugar: {
        type: DataTypes.STRING(120),
        allowNull: false,
      },
      estado: {
        type: DataTypes.STRING(15),
        allowNull: false,
        defaultValue: "pendiente",
      },
      id_propuesta_anterior: {
        type: DataTypes.INTEGER,
        allowNull: true,
        references: { model: "propuestas_entrega", key: "id" },
      },
      creado_en: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    },
    {
      sequelize,
      tableName: "propuestas_entrega",
      schema: "public",
      timestamps: false,
    },
  );
};
