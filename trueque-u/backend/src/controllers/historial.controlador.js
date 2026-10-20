const { Op } = require("sequelize");
const { models } = require("../database/sequelize");

// GET /api/historial
// Lista lo que ocurrió con los intercambios de la persona con sesión:
// los eventos que hizo ella y los que hizo la otra parte con ella.
// Filtro opcional: ?tipo=reservas (reservó y canceló) o ?tipo=completados
const getHistorial = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const { tipo } = req.query;

    // Solo los eventos donde la persona participó
    const donde = {
      [Op.or]: [{ id_usuario: idUsuario }, { id_otro_usuario: idUsuario }],
    };

    // Filtro por tipo (si no se manda, se devuelve todo)
    if (tipo === "reservas") {
      donde.tipo = { [Op.in]: ["reservo", "cancelo_reserva"] };
    } else if (tipo === "completados") {
      donde.tipo = "completo";
    } else if (tipo !== undefined) {
      return res
        .status(400)
        .json({ error: "El tipo debe ser reservas o completados" });
    }

    const eventos = await models.historial.findAll({
      where: donde,
      include: [
        { model: models.usuarios, as: "quien_hizo", attributes: ["id", "nombre"] },
        { model: models.usuarios, as: "la_otra_parte", attributes: ["id", "nombre"] },
      ],
      order: [
        ["creado_en", "DESC"], // lo más reciente primero
        ["id", "DESC"], // si coinciden en la hora, el último guardado primero
      ],
    });

    // Se arma la respuesta desde el punto de vista de quien pregunta
    const lista = eventos.map((evento) => {
      const loHiceYo = evento.id_usuario === idUsuario;
      const otra = loHiceYo ? evento.la_otra_parte : evento.quien_hizo;
      return {
        id: evento.id,
        tipo: evento.tipo,
        creado_en: evento.creado_en,
        lo_hice_yo: loHiceYo,
        publicacion: {
          id: evento.id_publicacion, // null si la publicación ya se eliminó
          titulo: evento.titulo,
          categoria: evento.categoria,
        },
        otra_persona: { id: otra.id, nombre: otra.nombre },
      };
    });

    console.log(
      `[historial] Consulta: usuario ${idUsuario}, ${lista.length} eventos`,
    );
    res.json(lista);
  } catch (error) {
    console.error("Error al obtener el historial:", error);
    res.status(500).json({ error: "Error al obtener el historial" });
  }
};

module.exports = { getHistorial };
