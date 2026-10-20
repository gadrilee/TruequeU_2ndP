const { Op } = require("sequelize");
const { sequelize, models } = require("../database/sequelize");
const { puedeCompletarIntercambio } = require("../utils/reglasObjeto");

// Datos que se agregan a cada publicación: quién la creó y quién la reservó
const INCLUIR_USUARIOS = [
  { model: models.usuarios, as: "autor", attributes: ["id", "nombre"] },
  {
    model: models.usuarios,
    as: "usuario_reserva",
    attributes: ["id", "nombre"],
  },
];

// PUT /api/publicaciones/:id/intercambiado
// Completa el intercambio: la publicación pasa a "intercambiado".
// Solo se puede si está reservada y lo hace el dueño o quien la reservó
const putIntercambio = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;

    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ error: "El id no es válido" });
    }

    const publicacion = await models.publicaciones.findByPk(id, {
      include: INCLUIR_USUARIOS,
    });
    if (!publicacion) {
      return res.status(404).json({ error: "Publicación no encontrada" });
    }

    // Regla de negocio (está en utils/reglasObjeto.js)
    const regla = puedeCompletarIntercambio(publicacion, idUsuario);
    if (!regla.permitido) {
      console.log(
        `[intercambios] Bloqueado: publicación ${publicacion.id} (usuario ${idUsuario}): ${regla.motivo}`,
      );
      return res.status(regla.codigo).json({ error: regla.motivo });
    }

    // La otra persona del intercambio: si completa el dueño, es quien reservó;
    // si completa quien reservó, es el dueño
    const idOtraPersona =
      idUsuario === publicacion.id_usuario
        ? publicacion.id_usuario_reserva
        : publicacion.id_usuario;

    // Se guarda "intercambiado" (se mantiene quién reservó) y el evento juntos:
    // si algo falla, no se guarda nada
    await sequelize.transaction(async (t) => {
      await publicacion.update(
        { estado_publicacion: "intercambiado" },
        { transaction: t },
      );
      await models.historial.create(
        {
          tipo: "completo",
          id_publicacion: publicacion.id,
          titulo: publicacion.titulo,
          categoria: publicacion.categoria,
          id_usuario: idUsuario, // quien completó
          id_otro_usuario: idOtraPersona,
        },
        { transaction: t },
      );
    });
    console.log(
      `[historial] Evento guardado: completo (publicación ${publicacion.id}, usuario ${idUsuario})`,
    );
    await publicacion.reload({ include: INCLUIR_USUARIOS });

    console.log(
      `[intercambios] Completado: id ${publicacion.id} (usuario ${idUsuario})`,
    );
    res.json({ publicacion, mensaje: "Intercambio completado correctamente" });
  } catch (error) {
    console.error("Error al completar el intercambio:", error);
    res.status(500).json({ error: "Error al completar el intercambio" });
  }
};

// GET /api/publicaciones/intercambiadas
// Intercambios completados de la persona con sesión (como dueña o como quien reservó).
// Es lo que va en su perfil, bajo "Intercambios completados"
const getIntercambios = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;

    const publicaciones = await models.publicaciones.findAll({
      where: {
        estado_publicacion: "intercambiado",
        [Op.or]: [{ id_usuario: idUsuario }, { id_usuario_reserva: idUsuario }],
      },
      include: INCLUIR_USUARIOS,
      order: [["id", "DESC"]],
    });
    res.json(publicaciones);
  } catch (error) {
    console.error("Error al obtener los intercambios completados:", error);
    res.status(500).json({ error: "Error al obtener los intercambios" });
  }
};

module.exports = {
  putIntercambio,
  getIntercambios,
};
