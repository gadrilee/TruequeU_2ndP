const Sequelize = require("sequelize");
module.exports = function (sequelize, DataTypes) {
  return sequelize.define(
    "usuarios",
    {
      id: {
        autoIncrement: true,
        autoIncrementIdentity: true,
        type: DataTypes.INTEGER,
        allowNull: false,
        primaryKey: true,
      },
      nombre: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      correo: {
        type: DataTypes.STRING(150),
        allowNull: false,
        unique: "usuarios_correo_key",
      },
      contrasena_hash: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      creado_en: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.Sequelize.fn("now"),
      },
      telefono: {
        type: DataTypes.STRING(10),
        allowNull: true,
      },
      eliminado_en: {
        type: DataTypes.DATE,
        allowNull: true,
      },
    },
    {
      sequelize,
      tableName: "usuarios",
      schema: "public",
      timestamps: false,
      indexes: [
        {
          name: "usuarios_correo_key",
          unique: true,
          fields: [{ name: "correo" }],
        },
        {
          name: "usuarios_pkey",
          unique: true,
          fields: [{ name: "id" }],
        },
      ],
    },
  );
};
