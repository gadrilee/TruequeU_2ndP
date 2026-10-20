var DataTypes = require("sequelize").DataTypes;
var _account = require("./account");
var _invitation = require("./invitation");
var _historial = require("./historial");
var _jwks = require("./jwks");
var _member = require("./member");
var _organization = require("./organization");
var _project_config = require("./project_config");
var _publicaciones = require("./publicaciones");
var _sesiones = require("./sesiones");
var _session = require("./session");
var _user = require("./user");
var _usuarios = require("./usuarios");
var _verification = require("./verification");

function initModels(sequelize) {
  var account = _account(sequelize, DataTypes);
  var invitation = _invitation(sequelize, DataTypes);
  var historial = _historial(sequelize, DataTypes);
  var jwks = _jwks(sequelize, DataTypes);
  var member = _member(sequelize, DataTypes);
  var organization = _organization(sequelize, DataTypes);
  var project_config = _project_config(sequelize, DataTypes);
  var publicaciones = _publicaciones(sequelize, DataTypes);
  var sesiones = _sesiones(sequelize, DataTypes);
  var session = _session(sequelize, DataTypes);
  var user = _user(sequelize, DataTypes);
  var usuarios = _usuarios(sequelize, DataTypes);
  var verification = _verification(sequelize, DataTypes);

  invitation.belongsTo(organization, { as: "organization", foreignKey: "organizationId"});
  organization.hasMany(invitation, { as: "invitations", foreignKey: "organizationId"});
  member.belongsTo(organization, { as: "organization", foreignKey: "organizationId"});
  organization.hasMany(member, { as: "members", foreignKey: "organizationId"});
  account.belongsTo(user, { as: "user", foreignKey: "userId"});
  user.hasMany(account, { as: "accounts", foreignKey: "userId"});
  invitation.belongsTo(user, { as: "inviter", foreignKey: "inviterId"});
  user.hasMany(invitation, { as: "invitations", foreignKey: "inviterId"});
  member.belongsTo(user, { as: "user", foreignKey: "userId"});
  user.hasMany(member, { as: "members", foreignKey: "userId"});
  session.belongsTo(user, { as: "user", foreignKey: "userId"});
  user.hasMany(session, { as: "sessions", foreignKey: "userId"});
  publicaciones.belongsTo(usuarios, { as: "id_usuario_usuario", foreignKey: "id_usuario"});
  usuarios.hasMany(publicaciones, { as: "publicaciones", foreignKey: "id_usuario"});
  publicaciones.belongsTo(usuarios, { as: "id_usuario_reserva_usuario", foreignKey: "id_usuario_reserva"});
  usuarios.hasMany(publicaciones, { as: "id_usuario_reserva_publicaciones", foreignKey: "id_usuario_reserva"});
  historial.belongsTo(publicaciones, { as: "id_publicacion_publicacione", foreignKey: "id_publicacion"});
  publicaciones.hasMany(historial, { as: "historials", foreignKey: "id_publicacion"});
  historial.belongsTo(usuarios, { as: "id_usuario_usuario", foreignKey: "id_usuario"});
  usuarios.hasMany(historial, { as: "historials", foreignKey: "id_usuario"});
  historial.belongsTo(usuarios, { as: "id_otro_usuario_usuario", foreignKey: "id_otro_usuario"});
  usuarios.hasMany(historial, { as: "id_otro_usuario_historials", foreignKey: "id_otro_usuario"});
  sesiones.belongsTo(usuarios, { as: "usuario", foreignKey: "usuario_id"});
  usuarios.hasMany(sesiones, { as: "sesiones", foreignKey: "usuario_id"});

  return {
    account,
    historial,
    invitation,
    jwks,
    member,
    organization,
    project_config,
    publicaciones,
    sesiones,
    session,
    user,
    usuarios,
    verification,
  };
}
module.exports = initModels;
module.exports.initModels = initModels;
module.exports.default = initModels;
