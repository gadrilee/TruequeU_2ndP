const { parteDelIntercambio } = require("./reglasObjeto");

const LUGAR_MAXIMO = 120;

function fechaReal(texto) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;
  const [anio, mes, dia] = texto.split("-").map(Number);
  const fecha = new Date(Date.UTC(anio, mes - 1, dia));
  return (
    fecha.getUTCFullYear() === anio &&
    fecha.getUTCMonth() === mes - 1 &&
    fecha.getUTCDate() === dia
  );
}

// se deja un día de margen para no depender de la zona horaria de quien propone
function fechaYaPaso(texto, ahora) {
  const limite = Date.UTC(ahora.getUTCFullYear(), ahora.getUTCMonth(), ahora.getUTCDate() - 1);
  return Date.parse(`${texto}T00:00:00Z`) < limite;
}

function validarPropuesta(cuerpo, ahora = new Date()) {
  const texto = (valor) => (typeof valor === "string" ? valor.trim() : "");
  const fecha = texto(cuerpo?.fecha);
  const hora = texto(cuerpo?.hora);
  const lugar = texto(cuerpo?.lugar);

  if (!fechaReal(fecha)) {
    return { valido: false, motivo: "Escribe una fecha válida" };
  }
  if (fechaYaPaso(fecha, ahora)) {
    return { valido: false, motivo: "La fecha ya pasó, elige otra" };
  }
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(hora)) {
    return { valido: false, motivo: "Escribe una hora válida" };
  }
  if (lugar === "") {
    return { valido: false, motivo: "Escribe el lugar de la entrega" };
  }
  if (lugar.length > LUGAR_MAXIMO) {
    return { valido: false, motivo: `El lugar puede tener hasta ${LUGAR_MAXIMO} letras` };
  }
  return { valido: true, datos: { fecha, hora, lugar } };
}

function mismaPropuesta(a, b) {
  return (
    String(a.fecha) === String(b.fecha) &&
    String(a.hora).slice(0, 5) === String(b.hora).slice(0, 5) &&
    String(a.lugar).trim().toLowerCase() === String(b.lugar).trim().toLowerCase()
  );
}

function verificarParticipante({ oferta, pedida, ofrecida, idUsuario }) {
  if (!parteDelIntercambio(oferta, pedida, ofrecida, idUsuario)) {
    return {
      permitido: false,
      codigo: 403,
      motivo: "Solo quienes participan en el intercambio pueden coordinar la entrega",
    };
  }
  if (oferta.estado !== "aceptada") {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Solo se coordina la entrega de un intercambio acordado que aún no se completó",
    };
  }
  return { permitido: true };
}

function puedeProponerEntrega({ oferta, pedida, ofrecida, idUsuario, pendiente, vigente, cuerpo, ahora }) {
  const base = verificarParticipante({ oferta, pedida, ofrecida, idUsuario });
  if (!base.permitido) return base;

  const datos = validarPropuesta(cuerpo, ahora);
  if (!datos.valido) return { permitido: false, codigo: 400, motivo: datos.motivo };

  if (pendiente) {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Ya hay una propuesta esperando respuesta. Respóndela antes de hacer otra",
    };
  }
  if (vigente && mismaPropuesta(vigente, datos.datos)) {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Esa fecha, hora y lugar ya son el acuerdo vigente",
    };
  }
  return { permitido: true, datos: datos.datos };
}

function verificarRespuesta({ oferta, pedida, ofrecida, idUsuario, propuesta }) {
  const base = verificarParticipante({ oferta, pedida, ofrecida, idUsuario });
  if (!base.permitido) return base;

  if (propuesta.estado !== "pendiente") {
    return { permitido: false, codigo: 409, motivo: "Esta propuesta ya fue respondida" };
  }
  if (propuesta.id_usuario === idUsuario) {
    return {
      permitido: false,
      codigo: 403,
      motivo: "Tu propuesta espera la respuesta de la otra persona",
    };
  }
  return { permitido: true };
}

function puedeAceptarEntrega(datos) {
  return verificarRespuesta(datos);
}

function puedeContraproponerEntrega({ cuerpo, ahora, ...datos }) {
  const base = verificarRespuesta(datos);
  if (!base.permitido) return base;

  const nueva = validarPropuesta(cuerpo, ahora);
  if (!nueva.valido) return { permitido: false, codigo: 400, motivo: nueva.motivo };

  if (mismaPropuesta(datos.propuesta, nueva.datos)) {
    return {
      permitido: false,
      codigo: 409,
      motivo: "La contrapropuesta tiene que cambiar la fecha, la hora o el lugar",
    };
  }
  return { permitido: true, datos: nueva.datos };
}

module.exports = {
  validarPropuesta,
  mismaPropuesta,
  puedeProponerEntrega,
  puedeAceptarEntrega,
  puedeContraproponerEntrega,
};
