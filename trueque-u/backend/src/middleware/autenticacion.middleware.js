const { Op } = require("sequelize");
const { models } = require("../database/sequelize");
const { verificarToken } = require("../services/token.servicio");

// Deja pasar solo a quien tiene una sesión válida:
// token correcto, sesión abierta y sin venycer.
const exigirSesion = async (req, res, next) => {
  try {
    // 1. Se lee el token de la cabecera "Authorization: Bearer <token>"
    const cabecera = req.headers.authorization || "";
    const token = cabecera.startsWith("Bearer ") ? cabecera.slice(7) : null;
    if (!token) {
      return res.status(401).json({ error: "No has iniciado sesión" });
    }

    // 2. Se comprueba que el token sea auténtico y no haya vencido
    let datos;
    try {
      datos = verificarToken(token);
    } catch (error) {
      return res.status(401).json({ error: "Sesión inválida o vencida" });
    }

    // 3. Se busca la sesión: debe seguir abierta (cerrada_en vacío) y sin vencer
    const sesion = await models.sesiones.findOne({
      where: {
        id: datos.jti, // el id de la sesión viaja dentro del token
        cerrada_en: null,
        expira_en: { [Op.gt]: new Date() },
      },
      include: [
        { model: models.usuarios, as: "usuario", attributes: ["id", "nombre", "correo"] },
      ],
    });
    if (!sesion) {
      return res.status(401).json({ error: "Sesión cerrada o vencida" });
    }

    // 4. Los controladores leen quién es la persona en req.usuario
    req.usuario = sesion.usuario;
    req.sesionId = sesion.id;
    next();
  } catch (error) {
    console.error("Error al comprobar la sesión:", error);
    res.status(500).json({ error: "Error al comprobar la sesión" });
  }
};

module.exports = { exigirSesion };
