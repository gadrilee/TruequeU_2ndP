const { models } = require("../database/sequelize");

const getNotificaciones = async (req, res) => {
  try {
    const notificaciones = await models.notificaciones.findAll({
      where: { id_usuario: req.usuario.id },
      attributes: ["id", "mensaje", "leida", "creado_en"],
      order: [
        ["creado_en", "DESC"],
        ["id", "DESC"],
      ],
    });
    res.json(notificaciones);
  } catch (error) {
    console.error("Error al obtener los avisos:", error);
    res.status(500).json({ error: "Error al obtener tus avisos" });
  }
};

const putNotificacionLeida = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ error: "El id no es válido" });
    }

    const [actualizadas] = await models.notificaciones.update(
      { leida: true },
      { where: { id, id_usuario: req.usuario.id } },
    );
    if (actualizadas === 0) {
      return res.status(404).json({ error: "No se encontró el aviso" });
    }
    res.json({ ok: true });
  } catch (error) {
    console.error("Error al marcar el aviso como leído:", error);
    res.status(500).json({ error: "Error al actualizar el aviso" });
  }
};

module.exports = { getNotificaciones, putNotificacionLeida };
