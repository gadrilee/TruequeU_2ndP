const { sequelize, models } = require("../database/sequelize");
const { idValido } = require("../utils/idValido");
const { cargarOferta } = require("../utils/cargarOferta");
const { parteDelIntercambio } = require("../utils/reglasObjeto");
const {
  puedeProponerEntrega,
  puedeAceptarEntrega,
  puedeContraproponerEntrega,
} = require("../utils/reglasEntrega");

const INCLUIR_PROPONENTE = [
  { model: models.usuarios, as: "proponente", attributes: ["id", "nombre"] },
];

const MENSAJE_PENDIENTE = "Ya hay una propuesta esperando respuesta. Respóndela antes de hacer otra";

function aJson(propuesta) {
  const datos = propuesta.toJSON();
  datos.hora = String(datos.hora).slice(0, 5);
  return datos;
}

async function cargarPropuesta(id, transaction) {
  const propuesta = await models.propuestas_entrega.findByPk(id, {
    transaction,
    lock: transaction.LOCK.UPDATE,
  });
  if (!propuesta) return { codigo: 404, error: "Propuesta no encontrada" };
  const datos = await cargarOferta(propuesta.id_oferta, transaction);
  if (datos.error) return datos;
  return { propuesta, ...datos };
}

function buscarEstado(idOferta, estado, transaction) {
  return models.propuestas_entrega.findOne({
    where: { id_oferta: idOferta, estado },
    transaction,
  });
}

function responderError(res, error, texto) {
  if (error.name === "SequelizeUniqueConstraintError") {
    return res.status(409).json({ error: MENSAJE_PENDIENTE });
  }
  console.error(texto, error);
  return res.status(500).json({ error: texto });
}

const getPropuestasEntrega = async (req, res) => {
  try {
    const idOferta = idValido(req.query.id_oferta);
    if (!idOferta) return res.status(400).json({ error: "Indica la oferta del intercambio" });

    const datos = await cargarOferta(idOferta);
    if (datos.error) return res.status(datos.codigo).json({ error: datos.error });
    const { oferta, pedida, ofrecida } = datos;
    if (!parteDelIntercambio(oferta, pedida, ofrecida, req.usuario.id)) {
      return res.status(403).json({
        error: "Solo quienes participan en el intercambio pueden ver la coordinación de la entrega",
      });
    }

    const filas = await models.propuestas_entrega.findAll({
      where: { id_oferta: idOferta },
      include: INCLUIR_PROPONENTE,
      order: [["id", "ASC"]],
    });
    const propuestas = filas.map(aJson);
    res.json({
      propuestas,
      vigente: propuestas.find((p) => p.estado === "aceptada") || null,
      pendiente: propuestas.find((p) => p.estado === "pendiente") || null,
    });
  } catch (error) {
    console.error("Error al listar las propuestas de entrega:", error);
    res.status(500).json({ error: "Error al obtener la coordinación de la entrega" });
  }
};

const postPropuestaEntrega = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const idOferta = idValido(req.body?.id_oferta);
    if (!idOferta) return res.status(400).json({ error: "Indica la oferta del intercambio" });

    const resultado = await sequelize.transaction(async (t) => {
      const datos = await cargarOferta(idOferta, t);
      if (datos.error) return datos;
      const { oferta, pedida, ofrecida } = datos;

      const pendiente = await buscarEstado(oferta.id, "pendiente", t);
      const vigente = await buscarEstado(oferta.id, "aceptada", t);
      const regla = puedeProponerEntrega({
        oferta,
        pedida,
        ofrecida,
        idUsuario,
        pendiente,
        vigente,
        cuerpo: req.body,
      });
      if (!regla.permitido) return { codigo: regla.codigo, error: regla.motivo };

      const propuesta = await models.propuestas_entrega.create(
        { id_oferta: oferta.id, id_usuario: idUsuario, ...regla.datos, estado: "pendiente" },
        { transaction: t },
      );
      return { propuesta, reprograma: Boolean(vigente) };
    });

    if (resultado.error) return res.status(resultado.codigo).json({ error: resultado.error });

    await resultado.propuesta.reload({ include: INCLUIR_PROPONENTE });
    console.log(`[entregas] Propuesta: ${resultado.propuesta.id} en la oferta ${idOferta} (usuario ${idUsuario})`);
    res.status(201).json({
      propuesta: aJson(resultado.propuesta),
      mensaje: resultado.reprograma
        ? "Propuesta de reprogramación enviada. Mientras no la acepten, sigue el acuerdo anterior"
        : "Propuesta enviada. La otra persona puede aceptarla o contraproponer",
    });
  } catch (error) {
    responderError(res, error, "Error al enviar la propuesta de entrega");
  }
};

const postContrapropuestaEntrega = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const id = idValido(req.params.id);
    if (!id) return res.status(400).json({ error: "El id no es válido" });

    const resultado = await sequelize.transaction(async (t) => {
      const datos = await cargarPropuesta(id, t);
      if (datos.error) return datos;
      const { propuesta, oferta, pedida, ofrecida } = datos;

      const regla = puedeContraproponerEntrega({
        oferta,
        pedida,
        ofrecida,
        idUsuario,
        propuesta,
        cuerpo: req.body,
      });
      if (!regla.permitido) return { codigo: regla.codigo, error: regla.motivo };

      await propuesta.update({ estado: "contrapuesta" }, { transaction: t });
      const nueva = await models.propuestas_entrega.create(
        {
          id_oferta: oferta.id,
          id_usuario: idUsuario,
          ...regla.datos,
          estado: "pendiente",
          id_propuesta_anterior: propuesta.id,
        },
        { transaction: t },
      );
      return { nueva };
    });

    if (resultado.error) return res.status(resultado.codigo).json({ error: resultado.error });

    await resultado.nueva.reload({ include: INCLUIR_PROPONENTE });
    console.log(`[entregas] Contrapropuesta: ${resultado.nueva.id} sobre ${id} (usuario ${idUsuario})`);
    res.status(201).json({
      propuesta: aJson(resultado.nueva),
      mensaje: "Contrapropuesta enviada. La otra persona puede aceptarla o contraproponer",
    });
  } catch (error) {
    responderError(res, error, "Error al enviar la contrapropuesta");
  }
};

const putPropuestaEntregaAceptada = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const id = idValido(req.params.id);
    if (!id) return res.status(400).json({ error: "El id no es válido" });

    const resultado = await sequelize.transaction(async (t) => {
      const datos = await cargarPropuesta(id, t);
      if (datos.error) return datos;
      const { propuesta, oferta, pedida, ofrecida } = datos;

      const regla = puedeAceptarEntrega({ oferta, pedida, ofrecida, idUsuario, propuesta });
      if (!regla.permitido) return { codigo: regla.codigo, error: regla.motivo };

      const vigente = await buscarEstado(oferta.id, "aceptada", t);
      if (vigente) await vigente.update({ estado: "reemplazada" }, { transaction: t });
      await propuesta.update({ estado: "aceptada" }, { transaction: t });
      return { propuesta, reprograma: Boolean(vigente) };
    });

    if (resultado.error) return res.status(resultado.codigo).json({ error: resultado.error });

    await resultado.propuesta.reload({ include: INCLUIR_PROPONENTE });
    console.log(`[entregas] Aceptada: ${id} (usuario ${idUsuario})`);
    res.json({
      propuesta: aJson(resultado.propuesta),
      mensaje: resultado.reprograma
        ? "Aceptaste la reprogramación. Esa es ahora la fecha y el lugar de la entrega"
        : "Aceptaste la propuesta. Ya tienen fecha y lugar para la entrega",
    });
  } catch (error) {
    responderError(res, error, "Error al aceptar la propuesta de entrega");
  }
};

module.exports = {
  getPropuestasEntrega,
  postPropuestaEntrega,
  postContrapropuestaEntrega,
  putPropuestaEntregaAceptada,
};
