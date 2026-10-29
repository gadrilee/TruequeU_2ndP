const { Op } = require("sequelize");
const { models } = require("../database/sequelize");

async function estaEnOfertaPendiente(idPublicacion) {
  const cantidad = await models.ofertas.count({
    where: {
      estado: "pendiente",
      [Op.or]: [
        { id_publicacion_pedida: idPublicacion },
        { id_publicacion_ofrecida: idPublicacion },
      ],
    },
  });
  return cantidad > 0;
}

module.exports = { estaEnOfertaPendiente };
