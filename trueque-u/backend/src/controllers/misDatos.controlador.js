const { models } = require("../database/sequelize");

const NOMBRES_SECCIONES = [
  "perfil",
  "publicaciones",
  "ofertas_hechas",
  "ofertas_recibidas",
  "calificaciones_dadas",
  "calificaciones_recibidas",
  "historial",
];

const celdaCsv = (valor) => {
  if (valor === null || valor === undefined) return "";
  const texto = valor instanceof Date ? valor.toISOString() : String(valor);
  return `"${texto.replace(/"/g, '""')}"`;
};

const aCsv = (datos) => {
  const bloques = NOMBRES_SECCIONES.map((nombre) => {
    const filas = Array.isArray(datos[nombre]) ? datos[nombre] : [datos[nombre]];
    const lineas = [nombre];
    if (filas.length > 0) {
      const columnas = Object.keys(filas[0]);
      lineas.push(columnas.join(","));
      filas.forEach((fila) => {
        lineas.push(columnas.map((columna) => celdaCsv(fila[columna])).join(","));
      });
    }
    return lineas.join("\n");
  });
  return bloques.join("\n\n") + "\n";
};

const aplanarOferta = (oferta) => ({
  objeto_pedido: oferta.pedida.titulo,
  objeto_ofrecido: oferta.ofrecida.titulo,
  estado: oferta.estado,
  motivo_cancelacion: oferta.motivo_cancelacion,
  creado_en: oferta.creado_en,
});

const armarDatos = async (idUsuario) => {
  const perfil = await models.usuarios.findByPk(idUsuario, {
    attributes: ["nombre", "correo", "telefono", "creado_en"],
    raw: true,
  });

  const publicaciones = await models.publicaciones.findAll({
    where: { id_usuario: idUsuario },
    attributes: ["titulo", "descripcion", "categoria", "estado", "estado_publicacion"],
    order: [["id", "ASC"]],
    raw: true,
  });

  const atributosOferta = ["estado", "creado_en", "motivo_cancelacion"];

  const ofertasHechas = await models.ofertas.findAll({
    where: { id_usuario: idUsuario },
    attributes: atributosOferta,
    include: [
      { model: models.publicaciones, as: "pedida", attributes: ["titulo"] },
      { model: models.publicaciones, as: "ofrecida", attributes: ["titulo"] },
    ],
    order: [["id", "ASC"]],
    raw: true,
    nest: true,
  });

  const ofertasRecibidas = await models.ofertas.findAll({
    attributes: atributosOferta,
    include: [
      {
        model: models.publicaciones,
        as: "pedida",
        attributes: ["titulo"],
        where: { id_usuario: idUsuario },
      },
      { model: models.publicaciones, as: "ofrecida", attributes: ["titulo"] },
    ],
    order: [["id", "ASC"]],
    raw: true,
    nest: true,
  });

  const atributosCalificacion = ["puntaje", "comentario", "creado_en"];

  const calificacionesDadas = await models.calificaciones.findAll({
    where: { id_usuario: idUsuario },
    attributes: atributosCalificacion,
    order: [["id", "ASC"]],
    raw: true,
  });

  const calificacionesRecibidas = await models.calificaciones.findAll({
    where: { id_calificado: idUsuario },
    attributes: atributosCalificacion,
    order: [["id", "ASC"]],
    raw: true,
  });

  const historial = await models.historial.findAll({
    where: { id_usuario: idUsuario },
    attributes: ["tipo", "titulo", "categoria", "creado_en"],
    order: [["id", "ASC"]],
    raw: true,
  });

  return {
    perfil,
    publicaciones,
    ofertas_hechas: ofertasHechas.map(aplanarOferta),
    ofertas_recibidas: ofertasRecibidas.map(aplanarOferta),
    calificaciones_dadas: calificacionesDadas,
    calificaciones_recibidas: calificacionesRecibidas,
    historial,
  };
};

const getMisDatos = async (req, res) => {
  try {
    const formato = req.query.formato || "json";
    if (formato !== "json" && formato !== "csv") {
      return res.status(400).json({ error: "El formato debe ser json o csv" });
    }

    const datos = await armarDatos(req.usuario.id);

    if (formato === "csv") {
      res.setHeader("Content-Type", "text/csv; charset=utf-8");
      res.setHeader("Content-Disposition", 'attachment; filename="mis-datos.csv"');
      return res.send(aCsv(datos));
    }

    res.setHeader("Content-Disposition", 'attachment; filename="mis-datos.json"');
    res.json(datos);
  } catch (error) {
    console.error("Error al obtener mis datos:", error);
    res.status(500).json({ error: "Error al obtener tus datos" });
  }
};

module.exports = { getMisDatos };
