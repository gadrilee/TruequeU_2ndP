const { Op } = require("sequelize");
const { sequelize, models } = require("../database/sequelize");
const {
  puedeCrearOferta,
  puedeContraofertar,
  idReceptor,
} = require("../utils/reglasObjeto");

const INCLUIR_OFERTA = [
  { model: models.usuarios, as: "oferente", attributes: ["id", "nombre"] },
  {
    model: models.publicaciones,
    as: "pedida",
    attributes: ["id", "titulo", "categoria", "estado", "estado_publicacion", "id_usuario"],
    include: [{ model: models.usuarios, as: "autor", attributes: ["id", "nombre"] }],
  },
  {
    model: models.publicaciones,
    as: "ofrecida",
    attributes: ["id", "titulo", "categoria", "estado", "estado_publicacion", "id_usuario"],
    include: [{ model: models.usuarios, as: "autor", attributes: ["id", "nombre"] }],
  },
];

function idValido(valor) {
  const id = Number(valor);
  return Number.isInteger(id) && id > 0 ? id : null;
}

const postOferta = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const idPedida = idValido(req.body?.id_publicacion_pedida);
    const idOfrecida = idValido(req.body?.id_publicacion_ofrecida);
    if (!idPedida || !idOfrecida) {
      return res.status(400).json({
        error: "Indica la publicación que quieres y el objeto tuyo que ofreces",
      });
    }

    const pedida = await models.publicaciones.findByPk(idPedida);
    const ofrecida = await models.publicaciones.findByPk(idOfrecida);
    const ofrecidaYaPrometida = ofrecida
      ? (await models.ofertas.count({
          where: { id_publicacion_ofrecida: ofrecida.id, estado: "pendiente" },
        })) > 0
      : false;

    const regla = puedeCrearOferta({
      pedida,
      ofrecida,
      idUsuario,
      ofrecidaYaPrometida,
    });
    if (!regla.permitido) {
      return res.status(regla.codigo).json({ error: regla.motivo });
    }

    let oferta;
    try {
      oferta = await models.ofertas.create({
        id_publicacion_pedida: pedida.id,
        id_publicacion_ofrecida: ofrecida.id,
        id_usuario: idUsuario,
        estado: "pendiente",
      });
    } catch (error) {
      if (error.name === "SequelizeUniqueConstraintError") {
        return res.status(409).json({
          error:
            "Ese objeto ya está en otra oferta pendiente. Cancélala si quieres usarlo en otra",
        });
      }
      throw error;
    }

    await oferta.update({ id_negociacion: oferta.id });
    await oferta.reload({ include: INCLUIR_OFERTA });
    console.log(
      `[ofertas] Creada: ${oferta.id} (usuario ${idUsuario} ofrece ${ofrecida.id} por ${pedida.id})`,
    );
    res.status(201).json({ oferta, mensaje: "Oferta enviada. El dueño puede aceptarla o rechazarla" });
  } catch (error) {
    console.error("Error al crear la oferta:", error);
    res.status(500).json({ error: "Error al enviar la oferta" });
  }
};

const ULTIMAS_DE_CADA_NEGOCIACION = sequelize.literal(
  "(SELECT MAX(id) FROM ofertas GROUP BY id_negociacion)",
);

const RONDA = [
  sequelize.literal(
    '(SELECT COUNT(*)::int FROM ofertas o2 WHERE o2.id_negociacion = "ofertas"."id_negociacion")',
  ),
  "ronda",
];

const getOfertasRecibidas = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const ofertas = await models.ofertas.findAll({
      attributes: { include: [RONDA] },
      where: {
        id: { [Op.in]: ULTIMAS_DE_CADA_NEGOCIACION },
        id_usuario: { [Op.ne]: idUsuario },
      },
      include: INCLUIR_OFERTA,
      order: [
        ["creado_en", "DESC"],
        ["id", "DESC"],
      ],
    });
    const mias = ofertas.filter(
      (oferta) => idReceptor(oferta, oferta.pedida, oferta.ofrecida) === idUsuario,
    );
    res.json(mias);
  } catch (error) {
    console.error("Error al listar ofertas recibidas:", error);
    res.status(500).json({ error: "Error al obtener las ofertas recibidas" });
  }
};

const getOfertasEnviadas = async (req, res) => {
  try {
    const ofertas = await models.ofertas.findAll({
      attributes: { include: [RONDA] },
      where: {
        id: { [Op.in]: ULTIMAS_DE_CADA_NEGOCIACION },
        id_usuario: req.usuario.id,
      },
      include: INCLUIR_OFERTA,
      order: [
        ["creado_en", "DESC"],
        ["id", "DESC"],
      ],
    });
    res.json(ofertas);
  } catch (error) {
    console.error("Error al listar ofertas enviadas:", error);
    res.status(500).json({ error: "Error al obtener las ofertas enviadas" });
  }
};

async function buscarOfertaPendiente(id, transaction) {
  return models.ofertas.findByPk(id, {
    transaction,
    lock: transaction.LOCK.UPDATE,
  });
}

async function bloquearPublicaciones(idA, idB, transaction) {
  const ids = [idA, idB].sort((a, b) => a - b);
  const filas = {};
  for (const id of ids) {
    filas[id] = await models.publicaciones.findByPk(id, {
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
  }
  return filas;
}

const putOfertaAceptada = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const id = idValido(req.params.id);
    if (!id) return res.status(400).json({ error: "El id no es válido" });

    const resultado = await sequelize.transaction(async (t) => {
      const oferta = await buscarOfertaPendiente(id, t);
      if (!oferta) return { codigo: 404, error: "Oferta no encontrada" };
      if (oferta.estado !== "pendiente") {
        return { codigo: 409, error: "Esta oferta ya fue respondida" };
      }

      const pubs = await bloquearPublicaciones(
        oferta.id_publicacion_pedida,
        oferta.id_publicacion_ofrecida,
        t,
      );
      const pedida = pubs[oferta.id_publicacion_pedida];
      const ofrecida = pubs[oferta.id_publicacion_ofrecida];
      if (!pedida || !ofrecida) {
        return { codigo: 404, error: "Ya no existe alguna de las publicaciones" };
      }
      if (idReceptor(oferta, pedida, ofrecida) !== idUsuario) {
        return { codigo: 403, error: "Solo quien recibe la oferta puede aceptarla" };
      }
      if (
        pedida.estado_publicacion !== "disponible" ||
        ofrecida.estado_publicacion !== "disponible"
      ) {
        return {
          codigo: 409,
          error: "Algún objeto ya no está disponible. Rechaza esta oferta",
        };
      }

      await oferta.update({ estado: "aceptada" }, { transaction: t });
      await pedida.update(
        { estado_publicacion: "intercambiado", id_usuario_reserva: ofrecida.id_usuario },
        { transaction: t },
      );
      await ofrecida.update(
        { estado_publicacion: "intercambiado", id_usuario_reserva: pedida.id_usuario },
        { transaction: t },
      );

      await models.ofertas.update(
        { estado: "cancelada" },
        {
          where: {
            id: { [Op.ne]: oferta.id },
            estado: "pendiente",
            [Op.or]: [
              { id_publicacion_pedida: { [Op.in]: [pedida.id, ofrecida.id] } },
              { id_publicacion_ofrecida: { [Op.in]: [pedida.id, ofrecida.id] } },
            ],
          },
          transaction: t,
        },
      );

      const idOtro =
        idUsuario === ofrecida.id_usuario ? pedida.id_usuario : ofrecida.id_usuario;

      await models.historial.bulkCreate(
        [
          {
            tipo: "completo",
            id_publicacion: pedida.id,
            titulo: pedida.titulo,
            categoria: pedida.categoria,
            id_usuario: idUsuario,
            id_otro_usuario: idOtro,
          },
          {
            tipo: "completo",
            id_publicacion: ofrecida.id,
            titulo: ofrecida.titulo,
            categoria: ofrecida.categoria,
            id_usuario: idUsuario,
            id_otro_usuario: idOtro,
          },
        ],
        { transaction: t },
      );

      return { oferta };
    });

    if (resultado.error) {
      return res.status(resultado.codigo).json({ error: resultado.error });
    }

    await resultado.oferta.reload({ include: INCLUIR_OFERTA });
    console.log(`[ofertas] Aceptada: ${id} (usuario ${idUsuario})`);
    res.json({
      oferta: resultado.oferta,
      mensaje: "Aceptaste el trueque. Las dos publicaciones quedaron intercambiadas",
    });
  } catch (error) {
    console.error("Error al aceptar la oferta:", error);
    res.status(500).json({ error: "Error al aceptar la oferta" });
  }
};

async function cerrarOferta(req, res, estadoNuevo) {
  try {
    const idUsuario = req.usuario.id;
    const id = idValido(req.params.id);
    if (!id) return res.status(400).json({ error: "El id no es válido" });

    const resultado = await sequelize.transaction(async (t) => {
      const oferta = await buscarOfertaPendiente(id, t);
      if (!oferta) return { codigo: 404, error: "Oferta no encontrada" };
      if (oferta.estado !== "pendiente") {
        return { codigo: 409, error: "Esta oferta ya fue respondida" };
      }

      const pedida = await models.publicaciones.findByPk(oferta.id_publicacion_pedida, {
        transaction: t,
      });
      const ofrecida = await models.publicaciones.findByPk(oferta.id_publicacion_ofrecida, {
        transaction: t,
      });
      const esReceptor =
        pedida && ofrecida && idReceptor(oferta, pedida, ofrecida) === idUsuario;
      const esOferente = oferta.id_usuario === idUsuario;

      if (estadoNuevo === "rechazada" && !esReceptor) {
        return { codigo: 403, error: "Solo quien recibe la oferta puede rechazarla" };
      }
      if (estadoNuevo === "cancelada" && !esOferente) {
        return { codigo: 403, error: "Solo quien envió la oferta puede cancelarla" };
      }

      await oferta.update({ estado: estadoNuevo }, { transaction: t });
      return { oferta };
    });

    if (resultado.error) {
      return res.status(resultado.codigo).json({ error: resultado.error });
    }

    await resultado.oferta.reload({ include: INCLUIR_OFERTA });
    const mensaje =
      estadoNuevo === "rechazada" ? "Rechazaste la oferta" : "Cancelaste la oferta";
    console.log(`[ofertas] ${estadoNuevo}: ${id} (usuario ${idUsuario})`);
    res.json({ oferta: resultado.oferta, mensaje });
  } catch (error) {
    console.error(`Error al marcar la oferta como ${estadoNuevo}:`, error);
    res.status(500).json({ error: "Error al actualizar la oferta" });
  }
}

const postContraoferta = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const id = idValido(req.params.id);
    if (!id) return res.status(400).json({ error: "El id no es válido" });
    const idNueva = idValido(req.body?.id_publicacion_ofrecida);
    if (!idNueva) {
      return res.status(400).json({ error: "Indica el objeto que propones en la contraoferta" });
    }

    const resultado = await sequelize.transaction(async (t) => {
      const oferta = await buscarOfertaPendiente(id, t);
      if (!oferta) return { codigo: 404, error: "Oferta no encontrada" };

      const pedida = await models.publicaciones.findByPk(oferta.id_publicacion_pedida, {
        transaction: t,
      });
      const ofrecidaActual = await models.publicaciones.findByPk(
        oferta.id_publicacion_ofrecida,
        { transaction: t },
      );
      if (!pedida || !ofrecidaActual) {
        return { codigo: 404, error: "Ya no existe alguna de las publicaciones" };
      }
      const nueva = await models.publicaciones.findByPk(idNueva, { transaction: t });
      const nuevaYaPrometida = nueva
        ? (await models.ofertas.count({
            where: { id_publicacion_ofrecida: nueva.id, estado: "pendiente" },
            transaction: t,
          })) > 0
        : false;

      const regla = puedeContraofertar({
        oferta,
        pedida,
        ofrecidaActual,
        nueva,
        idUsuario,
        nuevaYaPrometida,
      });
      if (!regla.permitido) return { codigo: regla.codigo, error: regla.motivo };

      await oferta.update({ estado: "contraofertada" }, { transaction: t });
      const contraoferta = await models.ofertas.create(
        {
          id_publicacion_pedida: pedida.id,
          id_publicacion_ofrecida: nueva.id,
          id_usuario: idUsuario,
          estado: "pendiente",
          id_negociacion: oferta.id_negociacion,
          id_oferta_anterior: oferta.id,
        },
        { transaction: t },
      );
      return { contraoferta };
    });

    if (resultado.error) {
      return res.status(resultado.codigo).json({ error: resultado.error });
    }

    await resultado.contraoferta.reload({ include: INCLUIR_OFERTA });
    console.log(
      `[ofertas] Contraoferta: ${resultado.contraoferta.id} sobre ${id} (usuario ${idUsuario})`,
    );
    res.status(201).json({
      oferta: resultado.contraoferta,
      mensaje: "Contraoferta enviada. La otra persona puede aceptarla, rechazarla o responder",
    });
  } catch (error) {
    if (error.name === "SequelizeUniqueConstraintError") {
      return res.status(409).json({ error: "Ese objeto ya está en otra oferta pendiente" });
    }
    console.error("Error al crear la contraoferta:", error);
    res.status(500).json({ error: "Error al enviar la contraoferta" });
  }
};

const getHistorialOferta = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const id = idValido(req.params.id);
    if (!id) return res.status(400).json({ error: "El id no es válido" });

    const oferta = await models.ofertas.findByPk(id);
    if (!oferta) return res.status(404).json({ error: "Oferta no encontrada" });

    const propuestas = await models.ofertas.findAll({
      where: { id_negociacion: oferta.id_negociacion },
      include: INCLUIR_OFERTA,
      order: [["id", "ASC"]],
    });

    const primera = propuestas[0];
    const participa =
      primera.pedida.id_usuario === idUsuario || primera.ofrecida.id_usuario === idUsuario;
    if (!participa) {
      return res
        .status(403)
        .json({ error: "Solo quienes participan en la negociación pueden ver su historial" });
    }

    const ultima = propuestas[propuestas.length - 1];
    res.json({
      id_negociacion: oferta.id_negociacion,
      abierta: ultima.estado === "pendiente",
      propuestas: propuestas.map((propuesta, indice) => ({
        ...propuesta.toJSON(),
        ronda: indice + 1,
      })),
    });
  } catch (error) {
    console.error("Error al obtener el historial de la oferta:", error);
    res.status(500).json({ error: "Error al obtener el historial de la negociación" });
  }
};

const putOfertaRechazada = (req, res) => cerrarOferta(req, res, "rechazada");
const putOfertaCancelada = (req, res) => cerrarOferta(req, res, "cancelada");

module.exports = {
  postOferta,
  getOfertasRecibidas,
  getOfertasEnviadas,
  putOfertaAceptada,
  putOfertaRechazada,
  putOfertaCancelada,
  postContraoferta,
  getHistorialOferta,
};
