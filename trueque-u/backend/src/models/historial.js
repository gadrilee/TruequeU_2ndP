const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('historial', {
    id: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    tipo: {
      type: DataTypes.STRING(20),
      allowNull: false
    },
    id_publicacion: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'publicaciones',
        key: 'id'
      }
    },
    titulo: {
      type: DataTypes.STRING(150),
      allowNull: false
    },
    categoria: {
      type: DataTypes.STRING(20),
      allowNull: false
    },
    id_usuario: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'usuarios',
        key: 'id'
      }
    },
    id_otro_usuario: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'usuarios',
        key: 'id'
      }
    },
    creado_en: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: Sequelize.Sequelize.fn('now')
    }
  }, {
    sequelize,
    tableName: 'historial',
    schema: 'public',
    timestamps: false,
    indexes: [
      {
        name: "historial_otro_idx",
        fields: [
          { name: "id_otro_usuario" },
          { name: "creado_en", order: "DESC" },
        ]
      },
      {
        name: "historial_pkey",
        unique: true,
        fields: [
          { name: "id" },
        ]
      },
      {
        name: "historial_usuario_idx",
        fields: [
          { name: "id_usuario" },
          { name: "creado_en", order: "DESC" },
        ]
      },
    ]
  });
};
