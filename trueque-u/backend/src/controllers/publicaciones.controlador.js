const { Op } = require("sequelize");
const { models } = require("../database/sequelize");
const { estaReservado, estaIntercambiado } = require("../utils/reglasObjeto");
const { estaEnOfertaPendiente } = require("../utils/ofertasPendientes");

// Condición del objeto: solo puede ser "nuevo" o "usado"
const ESTADOS = ["nuevo", "usado"];

// Categorías permitidas
const CATEGORIAS = ["libros", "electronica", "ropa", "otros"];

// Disponibilidad que se puede usar para filtrar el catálogo
const DISPONIBILIDADES = ["disponible", "reservado", "intercambiado"];

// Datos que se agregan a cada publicación: quién la creó y quién la reservó
const INCLUIR_USUARIOS = [
  { model: models.usuarios, as: "autor", attributes: ["id", "nombre"] },
  {
    model: models.usuarios,
    as: "usuario_reserva",
    attributes: ["id", "nombre"],
  },
];

// Igual que INCLUIR_USUARIOS, pero con el teléfono de quien reservó.
// Se usa solo cuando quien mira es el dueño de la publicación
const INCLUIR_USUARIOS_DUENO = [
  { model: models.usuarios, as: "autor", attributes: ["id", "nombre"] },
  {
    model: models.usuarios,
    as: "usuario_reserva",
    attributes: ["id", "nombre", "telefono"],
  },
];

// Catálogo general: el autor trae su teléfono para que quien reserve pueda
// contactarlo (H7). El teléfono se quita abajo para todos los demás.
const INCLUIR_USUARIOS_CATALOGO = [
  {
    model: models.usuarios,
    as: "autor",
    attributes: ["id", "nombre", "telefono"],
  },
  { model: models.usuarios, as: "usuario_reserva", attributes: ["id", "nombre"] },
];

// GET /api/publicaciones
// Catálogo general. Por defecto no muestra las ocultas ni las intercambiadas.
// Quién reservó solo lo ven el dueño y quien reservó.
// Búsqueda y filtros opcionales (se pueden combinar), por ejemplo:
// /api/publicaciones?buscar=libro&categoria=libros&condicion=usado&disponibilidad=disponible
const getPublicaciones = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const { buscar, categoria, condicion, disponibilidad } = req.query;

    // Por defecto: todo menos lo oculto y lo intercambiado
    const donde = {
      estado_publicacion: { [Op.notIn]: ["oculto", "intercambiado"] },
    };

    // Buscar por título (sin importar mayúsculas)
    if (typeof buscar === "string" && buscar.trim() !== "") {
      const texto = buscar.trim().replace(/[%_\\]/g, "\\$&"); // para que % y _ se busquen como texto normal
      donde.titulo = { [Op.iLike]: `%${texto}%` };
    }

    // Filtrar por categoría
    if (typeof categoria === "string" && categoria !== "") {
      if (!CATEGORIAS.includes(categoria)) {
        return res.status(400).json({
          error: "La categoría debe ser libros, electronica, ropa u otros",
        });
      }
      donde.categoria = categoria;
    }

    // Filtrar por condición del objeto (nuevo o usado)
    if (typeof condicion === "string" && condicion !== "") {
      if (!ESTADOS.includes(condicion)) {
        return res
          .status(400)
          .json({ error: "La condición debe ser nuevo o usado" });
      }
      donde.estado = condicion;
    }

    // Filtrar por disponibilidad (aquí sí se pueden ver las intercambiadas)
    if (typeof disponibilidad === "string" && disponibilidad !== "") {
      if (!DISPONIBILIDADES.includes(disponibilidad)) {
        return res.status(400).json({
          error: "La disponibilidad debe ser disponible, reservado o intercambiado",
        });
      }
      donde.estado_publicacion = disponibilidad;
    }

    const publicaciones = await models.publicaciones.findAll({
      where: donde,
      include: INCLUIR_USUARIOS_CATALOGO,
      order: [["id", "DESC"]], // las más nuevas primero
    });

    // Quién reservó lo ven solo el dueño y quien reservó.
    // Para el resto la publicación solo figura como "reservado"
    const lista = publicaciones.map((publicacion) => {
      const datos = publicacion.toJSON();
      const esDueno = datos.id_usuario === idUsuario;
      const esQuienReservo = datos.id_usuario_reserva === idUsuario;
      if (!esDueno && !esQuienReservo) {
        datos.id_usuario_reserva = null;
        datos.usuario_reserva = null;
      }
      // El teléfono del dueño solo lo recibe quien reservó (mientras esté reservada)
      const puedeVerTelefono =
        esQuienReservo && datos.estado_publicacion === "reservado";
      if (datos.autor && !puedeVerTelefono) {
        datos.autor = { ...datos.autor };
        delete datos.autor.telefono;
      }
      return datos;
    });
    res.json(lista);
  } catch (error) {
    console.error("Error al obtener el feed de publicaciones:", error);
    res.status(500).json({ error: "Error al obtener las publicaciones" });
  }
};

// GET /api/publicaciones/mias
// Solo las publicaciones de la persona con sesión, en cualquier estado menos "intercambiado"
// (las intercambiadas salen en GET /api/publicaciones/intercambiadas).
// Aquí el dueño también ve el teléfono de quien reservó
const getMisPublicaciones = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;

    const publicaciones = await models.publicaciones.findAll({
      where: {
        id_usuario: idUsuario,
        estado_publicacion: { [Op.ne]: "intercambiado" },
      },
      include: INCLUIR_USUARIOS_DUENO,
      order: [["id", "DESC"]],
    });
    res.json(publicaciones);
  } catch (error) {
    console.error("Error al obtener mis publicaciones:", error);
    res.status(500).json({ error: "Error al obtener tus publicaciones" });
  }
};

// GET /api/publicaciones/:id
// Una publicación por su id. Si está oculta, solo la ve su creador.
// Quién reservó solo lo ven el dueño y quien reservó
const getPublicacion = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;

    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ error: "El id no es válido" });
    }

    const publicacion = await models.publicaciones.findByPk(id, {
      include: INCLUIR_USUARIOS,
    });

    const esOculta = publicacion && publicacion.estado_publicacion === "oculto";
    if (!publicacion || (esOculta && publicacion.id_usuario !== idUsuario)) {
      return res.status(404).json({ error: "Publicación no encontrada" });
    }

    const esDueno = publicacion.id_usuario === idUsuario;
    const esQuienReservo = publicacion.id_usuario_reserva === idUsuario;

    // Si quien mira es el dueño, se vuelve a leer con el teléfono de quien reservó
    if (esDueno) {
      await publicacion.reload({ include: INCLUIR_USUARIOS_DUENO });
    }

    // Quién reservó lo ven solo el dueño y quien reservó
    const datos = publicacion.toJSON();
    if (!esDueno && !esQuienReservo) {
      datos.id_usuario_reserva = null;
      datos.usuario_reserva = null;
    }

    res.json(datos);
  } catch (error) {
    console.error("Error al obtener la publicación:", error);
    res.status(500).json({ error: "Error al obtener la publicación" });
  }
};

// POST /api/publicaciones
// Crea una publicación de la persona con sesión (nace "disponible")
const postPublicacion = async (req, res) => {
  try {
    const idUsuario = req.usuario.id;
    const { titulo, descripcion, estado, categoria } = req.body || {};

    // Se validan los datos que llegan
    if (typeof titulo !== "string" || titulo.trim().length < 2) {
      return res
        .status(400)
        .json({ error: "Escribe un título (mínimo 2 letras)" });
    }
    if (titulo.trim().length > 150) {
      return res
        .status(400)
        .json({ error: "El título es muy largo (máximo 150)" });
    }
    if (!ESTADOS.includes(estado)) {
      return res
        .status(400)
        .json({ error: "El estado debe ser nuevo o usado" });
    }

    // La categoría es opcional; si no llega, queda en "otros"
    if (categoria !== undefined && !CATEGORIAS.includes(categoria)) {
      return res.status(400).json({
        error: "La categoría debe ser libros, electronica, ropa u otros",
      });
    }

    const nueva = await models.publicaciones.create({
      id_usuario: idUsuario,
      titulo: titulo.trim(),
      descripcion: typeof descripcion === "string" ? descripcion.trim() : null,
      estado,
      categoria: categoria || "otros",
    });

    // Se vuelve a leer para devolverla con los datos del autor
    const publicacion = await models.publicaciones.findByPk(nueva.id, {
      include: INCLUIR_USUARIOS,
    });

    console.log(`[publicaciones] Creada: id ${nueva.id} (usuario ${idUsuario})`);
    res.status(201).json(publicacion);
  } catch (error) {
    console.error("Error al crear publicación:", error);
    res.status(500).json({ error: "Error al crear la publicación" });
  }
};

// PUT /api/publicaciones/:id
// Edita título, descripción, condición o categoría. No se puede si está reservada o intercambiada
const putPublicacion = async (req, res) => {
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

    // Solo el creador puede editarla
    if (publicacion.id_usuario !== idUsuario) {
      return res.status(403).json({ error: "Esta publicación no es tuya" });
    }

    // Regla: una publicación reservada no se puede editar
    if (estaReservado(publicacion)) {
      console.log(
        `[publicaciones] Bloqueado: no se puede editar la publicación ${publicacion.id}, está reservada`,
      );
      return res.status(409).json({
        error: "No puedes editar una publicación que ya fue reservada",
      });
    }

    // Regla: una publicación intercambiada ya terminó, no se puede editar
    if (estaIntercambiado(publicacion)) {
      return res.status(409).json({
        error: "No puedes editar una publicación que ya fue intercambiada",
      });
    }

    const { titulo, descripcion, estado, categoria } = req.body || {};
    const cambios = {}; // aquí se van juntando solo los datos que llegaron

    if (titulo !== undefined) {
      if (
        typeof titulo !== "string" ||
        titulo.trim().length < 2 ||
        titulo.trim().length > 150
      ) {
        return res
          .status(400)
          .json({ error: "El título debe tener entre 2 y 150 letras" });
      }
      cambios.titulo = titulo.trim();
    }
    if (descripcion !== undefined) {
      cambios.descripcion =
        typeof descripcion === "string" ? descripcion.trim() : null;
    }
    if (estado !== undefined) {
      if (!ESTADOS.includes(estado)) {
        return res
          .status(400)
          .json({ error: "El estado debe ser nuevo o usado" });
      }
      cambios.estado = estado;
    }
    if (categoria !== undefined) {
      if (!CATEGORIAS.includes(categoria)) {
        return res.status(400).json({
          error: "La categoría debe ser libros, electronica, ropa u otros",
        });
      }
      cambios.categoria = categoria;
    }

    await publicacion.update(cambios);
    await publicacion.reload({ include: INCLUIR_USUARIOS });

    console.log(
      `[publicaciones] Actualizada: id ${publicacion.id} (usuario ${idUsuario})`,
    );
    res.json({ publicacion, mensaje: "Publicación actualizada correctamente" });
  } catch (error) {
    console.error("Error al actualizar publicación:", error);
    res.status(500).json({ error: "Error al actualizar la publicación" });
  }
};

// DELETE /api/publicaciones/:id
// Elimina para siempre una publicación propia. No se puede si está reservada o intercambiada
const deletePublicacion = async (req, res) => {
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

    // Solo el creador puede eliminarla
    if (publicacion.id_usuario !== idUsuario) {
      return res.status(403).json({ error: "Esta publicación no es tuya" });
    }

    // Regla: una publicación reservada no se puede eliminar
    if (estaReservado(publicacion)) {
      console.log(
        `[publicaciones] Bloqueado: no se puede eliminar la publicación ${publicacion.id}, está reservada`,
      );
      return res.status(409).json({
        error: "No puedes eliminar una publicación que ya fue reservada",
      });
    }

    // Regla: una publicación intercambiada ya terminó, no se puede eliminar
    if (estaIntercambiado(publicacion)) {
      return res.status(409).json({
        error: "No puedes eliminar una publicación que ya fue intercambiada",
      });
    }

    if (await estaEnOfertaPendiente(publicacion.id)) {
      return res.status(409).json({
        error:
          "No puedes eliminar una publicación con una oferta pendiente. Responde o cancela la oferta primero",
      });
    }

    await publicacion.destroy();

    console.log(
      `[publicaciones] Eliminada: id ${publicacion.id} (usuario ${idUsuario})`,
    );
    res.json({ mensaje: "Publicación eliminada correctamente" });
  } catch (error) {
    console.error("Error al eliminar publicación:", error);
    res.status(500).json({ error: "Error al eliminar la publicación" });
  }
};

// PUT /api/publicaciones/:id/oculto
// El creador oculta su publicación del feed. No se puede si está reservada o intercambiada
const putPublicacionOculto = async (req, res) => {
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

    // Solo el creador puede ocultarla
    if (publicacion.id_usuario !== idUsuario) {
      return res.status(403).json({ error: "Esta publicación no es tuya" });
    }

    // Regla: una publicación reservada no se puede ocultar
    if (estaReservado(publicacion)) {
      console.log(
        `[publicaciones] Bloqueado: no se puede ocultar la publicación ${publicacion.id}, está reservada`,
      );
      return res.status(409).json({
        error: "No puedes ocultar una publicación que ya fue reservada",
      });
    }

    // Regla: una publicación intercambiada ya terminó, no se puede ocultar
    if (estaIntercambiado(publicacion)) {
      return res.status(409).json({
        error: "No puedes ocultar una publicación que ya fue intercambiada",
      });
    }

    if (await estaEnOfertaPendiente(publicacion.id)) {
      return res.status(409).json({
        error:
          "No puedes ocultar una publicación con una oferta pendiente. Responde o cancela la oferta primero",
      });
    }

    await publicacion.update({
      estado_publicacion: "oculto",
      id_usuario_reserva: null,
    });
    await publicacion.reload({ include: INCLUIR_USUARIOS });

    console.log(
      `[publicaciones] Oculta: id ${publicacion.id} (usuario ${idUsuario})`,
    );
    res.json({ publicacion, mensaje: 'Publicación ahora está "oculto"' });
  } catch (error) {
    console.error("Error al ocultar publicación:", error);
    res
      .status(500)
      .json({ error: "Error al cambiar el estado de la publicación" });
  }
};

// PUT /api/publicaciones/:id/no-disponible
// El creador marca el objeto como no disponible (por ejemplo, ya se intercambió).
// No se puede si está reservada o intercambiada
const putPublicacionNoDisponible = async (req, res) => {
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

    // Solo el creador puede marcarla como no disponible
    if (publicacion.id_usuario !== idUsuario) {
      return res.status(403).json({ error: "Esta publicación no es tuya" });
    }

    // Regla: una publicación reservada no se puede marcar como no disponible
    if (estaReservado(publicacion)) {
      console.log(
        `[publicaciones] Bloqueado: no se puede marcar como no disponible la publicación ${publicacion.id}, está reservada`,
      );
      return res.status(409).json({
        error:
          "No puedes marcar como no disponible una publicación que ya fue reservada",
      });
    }

    // Regla: una publicación intercambiada ya terminó, no se puede marcar como no disponible
    if (estaIntercambiado(publicacion)) {
      return res.status(409).json({
        error: "No puedes marcar como no disponible una publicación que ya fue intercambiada",
      });
    }

    if (await estaEnOfertaPendiente(publicacion.id)) {
      return res.status(409).json({
        error:
          "No puedes marcar como no disponible una publicación con una oferta pendiente. Responde o cancela la oferta primero",
      });
    }

    await publicacion.update({
      estado_publicacion: "no disponible",
      id_usuario_reserva: null,
    });
    await publicacion.reload({ include: INCLUIR_USUARIOS });

    console.log(
      `[publicaciones] No disponible: id ${publicacion.id} (usuario ${idUsuario})`,
    );
    res.json({
      publicacion,
      mensaje: 'Publicación ahora está "no disponible"',
    });
  } catch (error) {
    console.error("Error al marcar publicación como no disponible:", error);
    res
      .status(500)
      .json({ error: "Error al cambiar el estado de la publicación" });
  }
};

module.exports = {
  getPublicaciones,
  getMisPublicaciones,
  getPublicacion,
  postPublicacion,
  putPublicacion,
  deletePublicacion,
  putPublicacionOculto,
  putPublicacionNoDisponible,
};
