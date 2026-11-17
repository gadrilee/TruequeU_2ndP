const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('publicaciones', {
    id: {
      autoIncrement: true,
      autoIncrementIdentity: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    id_usuario: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'usuarios',
        key: 'id'
      }
    },
    titulo: {
      type: DataTypes.STRING(150),
      allowNull: false
    },
    descripcion: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    imagen_url: {
      type: DataTypes.STRING(500),
      allowNull: true
    },
    estado: {
      type: DataTypes.STRING(10),
      allowNull: false
    },
    estado_publicacion: {
      type: DataTypes.STRING(15),
      allowNull: false,
      defaultValue: "disponible"
    },
    categoria: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: "otros"
    },
    id_usuario_reserva: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'usuarios',
        key: 'id'
      }
    }
  }, {
    sequelize,
    tableName: 'publicaciones',
    schema: 'public',
    timestamps: false,
    indexes: [
      {
        name: "publicaciones_pkey",
        unique: true,
        fields: [
          { name: "id" },
        ]
      },
      {
        name: "publicaciones_usuario_idx",
        fields: [
          { name: "id_usuario" },
        ]
      },
    ]
  });
};
