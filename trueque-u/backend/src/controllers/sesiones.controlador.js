const { models } = require("../database/sequelize");
const { crearSesion } = require("../services/sesion.servicio");
const { coincide } = require("../services/contrasena.servicio");
const { firmarToken } = require("../services/token.servicio");
const { usuarioPublico } = require("../utils/serializadores");

// POST /api/sesiones
// Inicia sesión con correo y contraseña
const postSesion = async (req, res) => {
  try {
    const { correo, contrasena } = req.body || {};
    if (typeof correo !== "string" || typeof contrasena !== "string") {
      return res
        .status(400)
        .json({ error: "Correo y contraseña son obligatorios" });
    }

    // Se busca la cuenta por correo y se compara la contraseña
    const usuario = await models.usuarios.findOne({
      where: { correo: correo.trim().toLowerCase() },
    });
    if (!usuario || usuario.eliminado_en || !(await coincide(contrasena, usuario.contrasena_hash))) {
      // El mismo mensaje en ambos casos, para no revelar si el correo existe
      return res.status(401).json({ error: "Correo o contraseña incorrectos" });
    }

    // Se abre una sesión nueva y se devuelve su token
    const sesionId = await crearSesion(usuario.id);

    console.log(`[sesiones] Sesión iniciada: usuario ${usuario.id}`);
    res.json({
      token: firmarToken({ usuarioId: usuario.id, sesionId }),
      usuario: usuarioPublico(usuario),
    });
  } catch (error) {
    console.error("Error al iniciar sesión:", error);
    res.status(500).json({ error: "Error al iniciar sesión" });
  }
};

// GET /api/sesiones/actual
// Dice quién tiene la sesión abierta (la app lo usa al recargar la página)
const getSesionActual = (req, res) => {
  res.json({ usuario: usuarioPublico(req.usuario) });
};

// DELETE /api/sesiones/actual
// Cierra la sesión: el token deja de servir aunque no haya vencido
const deleteSesion = async (req, res) => {
  try {
    await models.sesiones.update(
      { cerrada_en: new Date() }, // se marca la hora en que se cerró
      { where: { id: req.sesionId } },
    );

    console.log(`[sesiones] Sesión cerrada: usuario ${req.usuario.id}`);
    res.json({ ok: true });
  } catch (error) {
    console.error("Error al cerrar sesión:", error);
    res.status(500).json({ error: "Error al cerrar sesión" });
  }
};

module.exports = { postSesion, getSesionActual, deleteSesion };
