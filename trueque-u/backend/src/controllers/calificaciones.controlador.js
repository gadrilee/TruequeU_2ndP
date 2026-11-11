const { col, fn } = require("sequelize");
const { models } = require("../database/sequelize");
const { idValido } = require("../utils/idValido");
const { cargarOferta } = require("../utils/cargarOferta");
const { puedeCalificar } = require("../utils/reglasCalificacion");

const getMiCalificacion = async (req, res) => {
  try {
    const idOferta = idValido(req.query.id_oferta);
    if (!idOferta) return res.status(400).json({ error: "Indica el intercambio" });

    const mia = await models.calificaciones.findOne({
      where: { id_oferta: idOferta, id_usuario: req.usuario.id },
    });
    res.json({ mia });
  } catch (error) {
    console.error("Error al obtener la calificación:", error);
    res.status(500).json({ error: "Error al obtener la calificación" });
  }
};

const postCalificacion = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const idOferta = idValido(req.body?.id_oferta);
    if (!idOferta) return res.status(400).json({ error: "Indica el intercambio que quieres calificar" });

    const datos = await cargarOferta(idOferta);
    if (datos.error) return res.status(datos.codigo).json({ error: datos.error });
    const { oferta, pedida, ofrecida } = datos;

    const previa = await models.calificaciones.findOne({
      where: { id_oferta: idOferta, id_usuario: idUsuario },
    });
    const regla = puedeCalificar({
      oferta,
      pedida,
      ofrecida,
      idUsuario,
      yaCalifico: Boolean(previa),
      cuerpo: req.body,
    });
    if (!regla.permitido) return res.status(regla.codigo).json({ error: regla.motivo });

    const calificacion = await models.calificaciones.create({
      id_oferta: idOferta,
      id_usuario: idUsuario,
      id_calificado: regla.idCalificado,
      ...regla.datos,
    });
    console.log(`[calificaciones] ${calificacion.id}: oferta ${idOferta} (usuario ${idUsuario})`);
    res.status(201).json({
      calificacion,
      mensaje: "Calificación enviada. Gracias por tu opinión",
    });
  } catch (error) {
    if (error.name === "SequelizeUniqueConstraintError") {
      return res.status(409).json({ error: "Ya calificaste este intercambio" });
    }
    console.error("Error al calificar el intercambio:", error);
    res.status(500).json({ error: "Error al calificar el intercambio" });
  }
};

const getResumenCalificaciones = async (req, res) => {
  try {
    const idUsuario = idValido(req.query.id_usuario);
    if (!idUsuario) return res.status(400).json({ error: "Indica la persona" });

    const fila = await models.calificaciones.findOne({
      attributes: [
        [fn("COUNT", col("id")), "cantidad"],
        [fn("AVG", col("puntaje")), "promedio"],
      ],
      where: { id_calificado: idUsuario },
      raw: true,
    });
    const cantidad = Number(fila.cantidad);
    res.json({
      cantidad,
      promedio: cantidad ? Math.round(Number(fila.promedio) * 10) / 10 : null,
    });
  } catch (error) {
    console.error("Error al obtener el resumen de calificaciones:", error);
    res.status(500).json({ error: "Error al obtener las calificaciones" });
  }
};

module.exports = { getMiCalificacion, postCalificacion, getResumenCalificaciones };
