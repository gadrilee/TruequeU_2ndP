const { models } = require("../database/sequelize");

async function cargarOferta(id, transaction) {
  const opciones = transaction ? { transaction, lock: transaction.LOCK.UPDATE } : {};
  const oferta = await models.ofertas.findByPk(id, opciones);
  if (!oferta) return { codigo: 404, error: "Oferta no encontrada" };
  const pedida = await models.publicaciones.findByPk(oferta.id_publicacion_pedida, { transaction });
  const ofrecida = await models.publicaciones.findByPk(oferta.id_publicacion_ofrecida, { transaction });
  if (!pedida || !ofrecida) {
    return { codigo: 404, error: "Ya no existe alguna de las publicaciones" };
  }
  return { oferta, pedida, ofrecida };
}

module.exports = { cargarOferta };
