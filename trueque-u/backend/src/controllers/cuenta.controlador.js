const crypto = require("crypto");
const { Op } = require("sequelize");
const { sequelize, models } = require("../database/sequelize");
const { coincide } = require("../services/contrasena.servicio");

const MOTIVO_CUENTA_ELIMINADA = "Cuenta del usuario eliminada";

const mensajeAviso = (titulo) =>
  `Tu trueque por "${titulo}" se canceló porque la otra persona eliminó su cuenta.`;

const cerrarTruequesEnCurso = async (idUsuario, idsPublicaciones, t) => {
  const ofertas = await models.ofertas.findAll({
    where: {
      estado: { [Op.in]: ["pendiente", "aceptada"] },
      [Op.or]: [
        { id_usuario: idUsuario },
        { id_publicacion_pedida: { [Op.in]: idsPublicaciones } },
        { id_publicacion_ofrecida: { [Op.in]: idsPublicaciones } },
      ],
    },
    include: [
      { model: models.publicaciones, as: "pedida" },
      { model: models.publicaciones, as: "ofrecida" },
    ],
    transaction: t,
  });

  const idsAnuladas = [];

  for (const oferta of ofertas) {
    const esMiaLaPedida = oferta.pedida.id_usuario === idUsuario;
    const publicacionOtra = esMiaLaPedida ? oferta.ofrecida : oferta.pedida;

    if (oferta.estado === "aceptada") {
      await oferta.update(
        {
          estado: "anulada",
          motivo_cancelacion: MOTIVO_CUENTA_ELIMINADA,
          id_usuario_cancela: idUsuario,
        },
        { transaction: t },
      );
      await publicacionOtra.update(
        { estado_publicacion: "disponible", id_usuario_reserva: null },
        { transaction: t },
      );
      idsAnuladas.push(oferta.id);
    } else {
      await oferta.update({ estado: "cancelada" }, { transaction: t });
    }

    await models.notificaciones.create(
      {
        id_usuario: publicacionOtra.id_usuario,
        mensaje: mensajeAviso(oferta.pedida.titulo),
      },
      { transaction: t },
    );
  }

  if (idsAnuladas.length > 0) {
    await models.propuestas_entrega.update(
      { estado: "reemplazada" },
      {
        where: {
          id_oferta: { [Op.in]: idsAnuladas },
          estado: { [Op.in]: ["pendiente", "aceptada"] },
        },
        transaction: t,
      },
    );
  }

  return ofertas.length;
};

const deleteCuenta = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const { contrasena } = req.body || {};

    const usuario = await models.usuarios.findByPk(idUsuario);
    if (
      !usuario ||
      typeof contrasena !== "string" ||
      !(await coincide(contrasena, usuario.contrasena_hash))
    ) {
      return res.status(401).json({ error: "La contraseña no es correcta" });
    }

    const truequesCancelados = await sequelize.transaction(async (t) => {
      const publicaciones = await models.publicaciones.findAll({
        where: { id_usuario: idUsuario },
        attributes: ["id"],
        transaction: t,
      });
      const idsPublicaciones = publicaciones.map((publicacion) => publicacion.id);

      const cancelados = await cerrarTruequesEnCurso(idUsuario, idsPublicaciones, t);

      await models.publicaciones.update(
        { estado_publicacion: "disponible", id_usuario_reserva: null },
        {
          where: { id_usuario_reserva: idUsuario, estado_publicacion: "reservado" },
          transaction: t,
        },
      );
      await models.publicaciones.update(
        { estado_publicacion: "oculto", id_usuario_reserva: null },
        {
          where: {
            id_usuario: idUsuario,
            estado_publicacion: { [Op.ne]: "intercambiado" },
          },
          transaction: t,
        },
      );

      await usuario.update(
        {
          nombre: "Usuario eliminado",
          correo: `eliminado-${idUsuario}@truequeu.local`,
          contrasena_hash: crypto.randomBytes(24).toString("hex"),
          telefono: null,
          eliminado_en: new Date(),
        },
        { transaction: t },
      );
      await models.sesiones.update(
        { cerrada_en: new Date() },
        { where: { usuario_id: idUsuario, cerrada_en: null }, transaction: t },
      );

      await models.eventos.create(
        { evento: "cuenta_eliminada", props: { trueques_cancelados: cancelados } },
        { transaction: t },
      );

      return cancelados;
    });

    console.log(`[usuarios] Cuenta eliminada: usuario ${idUsuario}`);
    res.json({
      ok: true,
      trueques_cancelados: truequesCancelados,
      mensaje: "Tu cuenta fue eliminada",
    });
  } catch (error) {
    console.error("Error al eliminar la cuenta:", error);
    res.status(500).json({ error: "Error al eliminar la cuenta" });
  }
};

module.exports = { deleteCuenta };
