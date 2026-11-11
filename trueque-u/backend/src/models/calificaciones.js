const Sequelize = require("sequelize");
module.exports = function (sequelize, DataTypes) {
  return sequelize.define(
    "calificaciones",
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
      id_calificado: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: "usuarios", key: "id" },
      },
      puntaje: {
        type: DataTypes.SMALLINT,
        allowNull: false,
      },
      comentario: {
        type: DataTypes.STRING(200),
        allowNull: true,
      },
      creado_en: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    },
    {
      sequelize,
      tableName: "calificaciones",
      schema: "public",
      timestamps: false,
    },
  );
};
