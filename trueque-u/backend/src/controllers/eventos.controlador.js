const { fn } = require("sequelize");
const { models } = require("../database/sequelize");

const CLAVES_PERSONALES = ["correo", "nombre", "telefono", "id_usuario", "email"];

const postEvento = async (req, res) => {
  try {
    const { evento, props } = req.body;

    if (typeof evento !== "string" || evento.trim() === "") {
      return res.status(400).json({ error: "El evento es obligatorio" });
    }

    const clavesProps = props && typeof props === "object" ? Object.keys(props) : [];
    if (clavesProps.some((clave) => CLAVES_PERSONALES.includes(clave.toLowerCase()))) {
      return res
        .status(400)
        .json({ error: "Los eventos no pueden llevar datos personales" });
    }

    await models.eventos.create({ evento: evento.trim(), props });

    console.log(`[eventos] Registrado: ${evento.trim()}`);
    res.status(201).json({ mensaje: "Evento registrado" });
  } catch (error) {
    console.error("Error al registrar el evento:", error);
    res.status(500).json({ error: "Error al registrar el evento" });
  }
};

const getAnalitica = async (req, res) => {
  try {
    const filas = await models.eventos.findAll({
      attributes: ["evento", [fn("COUNT", "*"), "total"]],
      group: ["evento"],
      raw: true,
    });

    const lista = filas.map((fila) => ({
      evento: fila.evento,
      total: Number(fila.total),
    }));

    res.json(lista);
  } catch (error) {
    console.error("Error al obtener la analítica:", error);
    res.status(500).json({ error: "Error al obtener la analítica" });
  }
};

module.exports = { postEvento, getAnalitica };
