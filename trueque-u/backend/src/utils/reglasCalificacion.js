const { parteDelIntercambio } = require("./reglasObjeto");

const COMENTARIO_MAXIMO = 200;

function validarCalificacion(cuerpo) {
  const puntaje = cuerpo?.puntaje;
  if (!Number.isInteger(puntaje) || puntaje < 1 || puntaje > 5) {
    return { valido: false, motivo: "El puntaje tiene que ser un número de 1 a 5" };
  }
  const comentario = cuerpo?.comentario ?? "";
  if (typeof comentario !== "string") {
    return { valido: false, motivo: "El comentario tiene que ser texto" };
  }
  if (comentario.trim().length > COMENTARIO_MAXIMO) {
    return { valido: false, motivo: `El comentario puede tener hasta ${COMENTARIO_MAXIMO} letras` };
  }
  return { valido: true, datos: { puntaje, comentario: comentario.trim() || null } };
}

function puedeCalificar({ oferta, pedida, ofrecida, idUsuario, yaCalifico, cuerpo }) {
  const parte = parteDelIntercambio(oferta, pedida, ofrecida, idUsuario);
  if (!parte) {
    return {
      permitido: false,
      codigo: 403,
      motivo: "Solo quienes participan en el intercambio pueden calificarlo",
    };
  }
  if (oferta.estado === "anulada") {
    return { permitido: false, codigo: 409, motivo: "Un intercambio cancelado no se puede calificar" };
  }
  if (oferta.estado !== "completada") {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Solo se puede calificar un intercambio completado",
    };
  }
  const datos = validarCalificacion(cuerpo);
  if (!datos.valido) return { permitido: false, codigo: 400, motivo: datos.motivo };

  if (yaCalifico) {
    return { permitido: false, codigo: 409, motivo: "Ya calificaste este intercambio" };
  }
  const idCalificado = parte === "pedida" ? ofrecida.id_usuario : pedida.id_usuario;
  return { permitido: true, datos: datos.datos, idCalificado };
}

module.exports = { validarCalificacion, puedeCalificar };
