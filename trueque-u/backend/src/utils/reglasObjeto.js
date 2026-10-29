// Una publicación reservada no puede editarse, eliminarse, ocultarse ni marcarse como no disponible
function estaReservado(publicacion) {
  return publicacion.estado_publicacion === "reservado";
}

// Una publicación intercambiada ya terminó: no puede reservarse, editarse,
// eliminarse, ocultarse ni completarse otra vez
function estaIntercambiado(publicacion) {
  return publicacion.estado_publicacion === "intercambiado";
}

// Regla para completar un intercambio.
// Solo se completa una publicación reservada, y solo lo hace el dueño o quien la reservó.
// Devuelve { permitido: true } o { permitido: false, codigo, motivo }
function puedeCompletarIntercambio(publicacion, idUsuario) {
  const esDueno = publicacion.id_usuario === idUsuario;
  const esQuienReservo = publicacion.id_usuario_reserva === idUsuario;

  if (!esDueno && !esQuienReservo) {
    return {
      permitido: false,
      codigo: 403,
      motivo: "Solo el dueño o quien reservó pueden completar el intercambio",
    };
  }
  if (estaIntercambiado(publicacion)) {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Este intercambio ya fue completado",
    };
  }
  if (!estaReservado(publicacion)) {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Solo se puede completar un intercambio de una publicación reservada. Primero debe reservarse",
    };
  }
  return { permitido: true };
}

function puedeCrearOferta({ pedida, ofrecida, idUsuario, ofrecidaYaPrometida }) {
  if (!pedida) {
    return { permitido: false, codigo: 404, motivo: "La publicación que quieres no existe" };
  }
  if (!ofrecida) {
    return { permitido: false, codigo: 404, motivo: "El objeto que ofreces no existe" };
  }
  if (pedida.id === ofrecida.id) {
    return {
      permitido: false,
      codigo: 400,
      motivo: "Tienes que ofrecer un objeto distinto del que quieres",
    };
  }
  if (pedida.id_usuario === idUsuario) {
    return {
      permitido: false,
      codigo: 403,
      motivo: "No puedes hacer una oferta por tu propia publicación",
    };
  }
  if (ofrecida.id_usuario !== idUsuario) {
    return {
      permitido: false,
      codigo: 403,
      motivo: "Solo puedes ofrecer un objeto de tus publicaciones",
    };
  }
  if (pedida.estado_publicacion !== "disponible") {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Solo puedes ofertar por una publicación disponible",
    };
  }
  if (ofrecida.estado_publicacion !== "disponible") {
    return {
      permitido: false,
      codigo: 409,
      motivo: "Solo puedes ofrecer un objeto tuyo que esté disponible",
    };
  }
  if (ofrecidaYaPrometida) {
    return {
      permitido: false,
      codigo: 409,
      motivo:
        "Ese objeto ya está en otra oferta pendiente. Cancélala si quieres usarlo en otra",
    };
  }
  return { permitido: true };
}

module.exports = {
  estaReservado,
  estaIntercambiado,
  puedeCompletarIntercambio,
  puedeCrearOferta,
};
