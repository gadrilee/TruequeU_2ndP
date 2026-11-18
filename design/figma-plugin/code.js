const TOKENS = {
  "TemaTruequeU": {
    "azul": "#2A3964",
    "azulOscuro": "#1B2645",
    "azulClaro": "#DDE3F2",
    "rojo": "#CC100C",
    "rojoClaro": "#FBE3E2",
    "rojoOscuro": "#8F0B08",
    "fondo": "#FAF7F2",
    "borde": "#E7E5E4",
    "verdeClaro": "#DCF2E3",
    "verdeOscuro": "#14532D",
    "blanco": "#FFFFFF",
    "texto": "#1C1917",
    "textoSuave": "#57534E",
    "contorno": "#78716C",
    "superficieAlta": "#F1ECE5"
  },
  "ColorScheme": {
    "primary": "TemaTruequeU/azul",
    "onPrimary": "TemaTruequeU/blanco",
    "primaryContainer": "TemaTruequeU/azulClaro",
    "onPrimaryContainer": "TemaTruequeU/azulOscuro",
    "secondary": "TemaTruequeU/rojo",
    "onSecondary": "TemaTruequeU/blanco",
    "secondaryContainer": "TemaTruequeU/rojoClaro",
    "onSecondaryContainer": "TemaTruequeU/rojoOscuro",
    "tertiary": "TemaTruequeU/verdeOscuro",
    "onTertiary": "TemaTruequeU/blanco",
    "tertiaryContainer": "TemaTruequeU/verdeClaro",
    "onTertiaryContainer": "TemaTruequeU/verdeOscuro",
    "error": "TemaTruequeU/rojo",
    "onError": "TemaTruequeU/blanco",
    "errorContainer": "TemaTruequeU/rojoClaro",
    "onErrorContainer": "TemaTruequeU/rojoOscuro",
    "surface": "TemaTruequeU/fondo",
    "onSurface": "TemaTruequeU/texto",
    "onSurfaceVariant": "TemaTruequeU/textoSuave",
    "outline": "TemaTruequeU/contorno",
    "outlineVariant": "TemaTruequeU/borde",
    "surfaceContainerHighest": "TemaTruequeU/superficieAlta"
  },
  "Espacios": {
    "e2": 2,
    "e4": 4,
    "e6": 6,
    "e8": 8,
    "e10": 10,
    "e12": 12,
    "e16": 16,
    "e20": 20,
    "e24": 24,
    "e32": 32,
    "e40": 40
  },
  "Radios": {
    "r8": 8,
    "r12": 12,
    "r14": 14,
    "r16": 16,
    "r20": 20,
    "r28": 28,
    "r36": 36
  },
  "Tipos": {
    "t11": 11,
    "t12": 12,
    "t13": 13,
    "t14": 14,
    "t16": 16,
    "t17": 17,
    "t18": 18,
    "t26": 26
  },
  "TextosTruequeU": {
    "titulo": {
      "fontSize": "Tipos/t26",
      "fontWeight": 700
    },
    "subtitulo": {
      "fontSize": "Tipos/t18",
      "fontWeight": 700
    },
    "tituloTarjeta": {
      "fontSize": "Tipos/t17",
      "fontWeight": 700
    },
    "tituloItem": {
      "fontSize": "Tipos/t16",
      "fontWeight": 700
    },
    "cuerpo": {
      "fontSize": "Tipos/t14",
      "fontWeight": 400
    },
    "detalle": {
      "fontSize": "Tipos/t13",
      "fontWeight": 400
    },
    "etiqueta": {
      "fontSize": "Tipos/t12",
      "fontWeight": 500
    },
    "ayuda": {
      "fontSize": "Tipos/t12",
      "fontWeight": 400
    },
    "chip": {
      "fontSize": "Tipos/t11",
      "fontWeight": 500
    },
    "chipDestacado": {
      "fontSize": "Tipos/t11",
      "fontWeight": 700
    },
    "pie": {
      "fontSize": "Tipos/t11",
      "fontWeight": 400
    }
  }
};

const FUENTE = 'Roboto';
const PESOS = { 400: 'Regular', 500: 'Medium', 700: 'Bold' };
const ALCANCES = {
  TemaTruequeU: ['ALL_FILLS', 'STROKE_COLOR'],
  ColorScheme: ['ALL_FILLS', 'STROKE_COLOR'],
  Espacios: ['GAP', 'WIDTH_HEIGHT'],
  Radios: ['CORNER_RADIUS'],
  Tipos: ['FONT_SIZE'],
};
const TIPOS_VARIABLE = {
  TemaTruequeU: 'COLOR',
  ColorScheme: 'COLOR',
  Espacios: 'FLOAT',
  Radios: 'FLOAT',
  Tipos: 'FLOAT',
};

const vars = {};
const estilos = {};
const conjuntos = {};

function valorHex(ruta) {
  const partes = ruta.split('/');
  const valor = TOKENS[partes[0]][partes[1]];
  if (valor === undefined) throw new Error('Token inexistente: ' + ruta);
  return valor.startsWith('#') ? valor : valorHex(valor);
}

function valorColor(ruta) {
  const n = parseInt(valorHex(ruta).slice(1), 16);
  return { r: ((n >> 16) & 255) / 255, g: ((n >> 8) & 255) / 255, b: (n & 255) / 255 };
}

function numero(ruta) {
  const partes = ruta.split('/');
  return TOKENS[partes[0]][partes[1]];
}

function variable(ruta) {
  const v = vars[ruta];
  if (!v) throw new Error('Token inexistente: ' + ruta);
  return v;
}

async function prepararVariables() {
  const colecciones = await figma.variables.getLocalVariableCollectionsAsync();
  const existentes = await figma.variables.getLocalVariablesAsync();
  const modos = {};

  for (const nombre of Object.keys(ALCANCES)) {
    let coleccion = colecciones.find(c => c.name === nombre);
    if (!coleccion) coleccion = figma.variables.createVariableCollection(nombre);
    coleccion.name = nombre;
    modos[nombre] = coleccion.modes[0].modeId;
    for (const campo of Object.keys(TOKENS[nombre])) {
      let v = existentes.find(x => x.variableCollectionId === coleccion.id && x.name === campo);
      if (!v) v = figma.variables.createVariable(campo, coleccion, TIPOS_VARIABLE[nombre]);
      v.scopes = ALCANCES[nombre];
      v.description = nombre + '.' + campo;
      vars[nombre + '/' + campo] = v;
    }
  }

  for (const nombre of Object.keys(ALCANCES)) {
    for (const campo of Object.keys(TOKENS[nombre])) {
      const v = vars[nombre + '/' + campo];
      const valor = TOKENS[nombre][campo];
      if (nombre === 'TemaTruequeU') {
        const c = valorColor(nombre + '/' + campo);
        v.setValueForMode(modos[nombre], { r: c.r, g: c.g, b: c.b, a: 1 });
      } else if (nombre === 'ColorScheme') {
        v.setValueForMode(modos[nombre], figma.variables.createVariableAlias(variable(valor)));
      } else {
        v.setValueForMode(modos[nombre], valor);
      }
    }
  }
}

async function prepararEstilos() {
  const existentes = await figma.getLocalTextStylesAsync();
  for (const campo of Object.keys(TOKENS.TextosTruequeU)) {
    const def = TOKENS.TextosTruequeU[campo];
    const nombre = 'TextosTruequeU/' + campo;
    let estilo = existentes.find(s => s.name === nombre);
    if (!estilo) estilo = figma.createTextStyle();
    estilo.name = nombre;
    estilo.fontName = { family: FUENTE, style: PESOS[def.fontWeight] };
    estilo.fontSize = numero(def.fontSize);
    estilo.setBoundVariable('fontSize', variable(def.fontSize));
    estilo.description = 'TextosTruequeU.' + campo;
    estilos[campo] = estilo;
  }
}

async function cargarFuentes() {
  for (const estilo of Object.values(PESOS)) {
    await figma.loadFontAsync({ family: FUENTE, style: estilo });
  }
}

function pintura(ruta, opacidad) {
  if (!/^(ColorScheme|TemaTruequeU)\//.test(ruta)) throw new Error('El color no es un token: ' + ruta);
  const base = { type: 'SOLID', color: valorColor(ruta) };
  const enlazada = figma.variables.setBoundVariableForPaint(base, 'color', variable(ruta));
  return opacidad === undefined ? enlazada : Object.assign({}, enlazada, { opacity: opacidad });
}

function degradado(desde, hasta) {
  const parada = (posicion, ruta) => {
    const c = valorColor(ruta);
    return {
      position: posicion,
      color: { r: c.r, g: c.g, b: c.b, a: 1 },
      boundVariables: { color: figma.variables.createVariableAlias(variable(ruta)) },
    };
  };
  return {
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[0, 1, 0], [-1, 0, 1]],
    gradientStops: [parada(0, desde), parada(1, hasta)],
  };
}

function ligar(nodo, campo, ruta) {
  nodo.setBoundVariable(campo, variable(ruta));
}

function relleno(f, pad) {
  if (!pad) return;
  let lados = pad;
  if (typeof pad === 'string') lados = [pad, pad, pad, pad];
  else if (pad.length === 2) lados = [pad[0], pad[1], pad[0], pad[1]];
  const campos = ['paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft'];
  campos.forEach((campo, i) => {
    if (!lados[i]) return;
    f[campo] = TOKENS.Espacios[lados[i]];
    ligar(f, campo, 'Espacios/' + lados[i]);
  });
}

function radio(nodo, r, esquinas) {
  const campos = esquinas || ['topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius'];
  for (const campo of campos) {
    nodo[campo] = TOKENS.Radios[r];
    ligar(nodo, campo, 'Radios/' + r);
  }
}

function marco(o) {
  const f = o.componente ? figma.createComponent() : figma.createFrame();
  f.name = o.nombre || 'Contenedor';
  f.layoutMode = o.dir === 'H' ? 'HORIZONTAL' : 'VERTICAL';
  f.fills = o.fondo ? [pintura(o.fondo, o.opacidad)] : [];
  f.strokes = o.borde ? [pintura(o.borde, o.opacidadBorde)] : [];
  if (o.borde) {
    f.strokeWeight = o.grosor || 1;
    f.strokeAlign = 'INSIDE';
  }
  if (o.ancho || o.alto) f.resize(o.ancho || f.width, o.alto || f.height);
  f.layoutSizingHorizontal = o.ancho ? 'FIXED' : 'HUG';
  f.layoutSizingVertical = o.alto ? 'FIXED' : 'HUG';
  f.primaryAxisAlignItems = o.alinea || 'MIN';
  f.counterAxisAlignItems = o.cruz || 'MIN';
  relleno(f, o.pad);
  if (o.gap) {
    f.itemSpacing = TOKENS.Espacios[o.gap];
    ligar(f, 'itemSpacing', 'Espacios/' + o.gap);
  }
  if (o.radio) radio(f, o.radio);
  f.clipsContent = !!o.recorta;
  return f;
}

function agregar(padre, hijo, o) {
  const opciones = o || {};
  padre.appendChild(hijo);
  if (opciones.ancho) hijo.layoutSizingHorizontal = 'FILL';
  if (opciones.alto) hijo.layoutSizingVertical = 'FILL';
  return hijo;
}

async function texto(contenido, estilo, color, nombre, opacidad) {
  const t = figma.createText();
  const def = TOKENS.TextosTruequeU[estilo];
  t.fontName = { family: FUENTE, style: PESOS[def.fontWeight] };
  t.characters = contenido;
  t.name = nombre || 'texto';
  await t.setTextStyleIdAsync(estilos[estilo].id);
  t.fills = [pintura(color, opacidad)];
  return t;
}

async function glifo(caracter, color, estilo, opacidad) {
  return texto(caracter, estilo || 'tituloItem', color, 'icono', opacidad);
}

function icono() {
  const v = figma.createVector();
  v.name = 'swap';
  v.vectorPaths = [{
    windingRule: 'NONE',
    data: 'M 0 8 L 32 8 M 24 0 L 32 8 L 24 16 M 32 28 L 0 28 M 8 20 L 0 28 L 8 36',
  }];
  v.fills = [];
  v.strokes = [pintura('TemaTruequeU/rojo')];
  v.strokeWeight = 4;
  v.strokeCap = 'ROUND';
  v.strokeJoin = 'ROUND';
  return v;
}

function combinaciones(props) {
  let acc = [{}];
  for (const clave of Object.keys(props)) {
    acc = acc.flatMap(a => props[clave].map(valor => Object.assign({}, a, { [clave]: valor })));
  }
  return acc;
}

function nombreVariante(c) {
  return Object.keys(c).map(k => k + '=' + c[k]).join(', ');
}

function esPropio(nodo, conjunto) {
  let actual = nodo.parent;
  while (actual && actual !== conjunto) {
    if (actual.type === 'INSTANCE') return false;
    actual = actual.parent;
  }
  return true;
}

function instancia(nombre, props) {
  const conjunto = conjuntos[nombre];
  const comp = conjunto.children.find(h => {
    const partes = h.name.split(', ');
    return Object.keys(props).every(k => partes.includes(k + '=' + props[k]));
  });
  if (!comp) throw new Error('Variante inexistente: ' + nombre + ' ' + nombreVariante(props));
  return comp.createInstance();
}

function cambiarTexto(inst, valor, nombre) {
  const t = inst.findOne(n => n.type === 'TEXT' && n.name === (nombre || 'texto'));
  if (t) t.characters = valor;
  return inst;
}

function disponer(comps, columnas) {
  const ancho = Math.max.apply(null, comps.map(c => c.width)) + 24;
  const alto = Math.max.apply(null, comps.map(c => c.height)) + 24;
  comps.forEach((c, i) => {
    c.x = (i % columnas) * ancho;
    c.y = Math.floor(i / columnas) * alto;
  });
}

async function mini(contenido, fondo, color) {
  const f = marco({ nombre: 'mini', dir: 'H', pad: ['e4', 'e8'], radio: 'r8', fondo: fondo, cruz: 'CENTER' });
  f.appendChild(await texto(contenido, 'chip', color, 'texto'));
  return f;
}

async function logo(c) {
  const conNombre = c.Variante === 'conNombre';
  const caja = marco({
    nombre: conNombre ? 'caja' : 'raiz', componente: !conNombre, dir: 'H', ancho: 64, alto: 64, radio: 'r20',
    fondo: 'TemaTruequeU/blanco', alinea: 'CENTER', cruz: 'CENTER',
  });
  caja.appendChild(icono());
  if (!conNombre) return caja;
  const fila = marco({ nombre: 'raiz', componente: true, dir: 'H', gap: 'e12', cruz: 'CENTER' });
  fila.appendChild(caja);
  fila.appendChild(await texto('Trueque U', 'titulo', 'ColorScheme/primary', 'nombre'));
  return fila;
}

async function botonCarga(c) {
  const pares = {
    primario: ['ColorScheme/primary', 'ColorScheme/onPrimary'],
    rojo: ['ColorScheme/secondary', 'ColorScheme/onSecondary'],
    tonal: ['ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer'],
    contorno: [null, 'ColorScheme/primary'],
    contornoRojo: [null, 'ColorScheme/error'],
    texto: [null, 'ColorScheme/primary'],
  };
  const par = pares[c.Variante];
  const contorno = c.Variante === 'contorno' || c.Variante === 'contornoRojo';
  const sinFondo = contorno || c.Variante === 'texto';
  const apagado = c.Estado === 'deshabilitado' || c.Estado === 'cargando';
  const opacidades = { default: 1, hover: 0.92, presionado: 0.84 };
  let fondo = par[0];
  let opacidad = opacidades[c.Estado];
  let color = par[1];
  let opacidadTexto;
  let borde = null;
  if (contorno) borde = c.Variante === 'contornoRojo' ? 'ColorScheme/error' : 'ColorScheme/outlineVariant';
  let opacidadBorde;
  if (sinFondo && (c.Estado === 'hover' || c.Estado === 'presionado')) {
    fondo = par[1];
    opacidad = c.Estado === 'hover' ? 0.08 : 0.12;
  }
  if (apagado) {
    fondo = sinFondo ? null : 'ColorScheme/onSurface';
    opacidad = 0.12;
    color = 'ColorScheme/onSurface';
    opacidadTexto = 0.38;
    if (contorno) {
      borde = 'ColorScheme/onSurface';
      opacidadBorde = 0.12;
    }
  }
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 280, alto: sinFondo ? 48 : 52, pad: [null, 'e16'],
    radio: 'r28', fondo: fondo, opacidad: opacidad, borde: borde, opacidadBorde: opacidadBorde,
    alinea: 'CENTER', cruz: 'CENTER',
  });
  if (c.Estado === 'cargando') {
    const giro = figma.createEllipse();
    giro.name = 'cargando';
    giro.resize(20, 20);
    giro.fills = [];
    giro.strokes = [pintura('ColorScheme/primary')];
    giro.strokeWeight = 2;
    giro.arcData = { startingAngle: 0, endingAngle: Math.PI * 1.5, innerRadius: 0 };
    f.appendChild(giro);
  } else {
    f.appendChild(await texto('Continuar', 'cuerpo', color, 'texto', opacidadTexto));
  }
  return f;
}

async function campoTexto(c) {
  const error = c.Estado === 'error';
  const enfocado = c.Estado === 'enfocado';
  const apagado = c.Estado === 'deshabilitado';
  const raiz = marco({ nombre: 'raiz', componente: true, dir: 'V', ancho: 320, gap: 'e4' });
  const multilinea = c.Tipo === 'multilinea';
  const caja = marco({
    nombre: 'campo', dir: 'H', alto: multilinea ? 96 : 56, pad: multilinea ? ['e12', 'e16'] : [null, 'e16'], gap: 'e12', radio: 'r14',
    fondo: apagado ? 'ColorScheme/surfaceContainerHighest' : 'TemaTruequeU/blanco',
    borde: error ? 'ColorScheme/error' : enfocado ? 'ColorScheme/primary' : 'ColorScheme/outlineVariant',
    grosor: error || enfocado ? 2 : 1, cruz: multilinea ? 'MIN' : 'CENTER',
  });
  agregar(raiz, caja, { ancho: true });
  const vacio = c.Estado === 'vacio';
  let contenido = vacio ? 'Correo' : 'ana@universidad.edu';
  if (c.Tipo === 'contrasena') contenido = vacio ? 'Contraseña' : '••••••••';
  if (multilinea) contenido = vacio ? 'Descripción (opcional)' : 'Casi nueva, incluye funda y manual.';
  if (c.Icono === 'si') caja.appendChild(await glifo('✉', 'ColorScheme/outline', 'cuerpo'));
  const t = await texto(contenido, 'cuerpo', vacio ? 'ColorScheme/onSurfaceVariant' : 'ColorScheme/onSurface', 'texto', apagado ? 0.38 : undefined);
  agregar(caja, t, { ancho: true });
  if (c.Tipo === 'contrasena') caja.appendChild(await texto('◉', 'cuerpo', 'ColorScheme/outline', 'ver'));
  if (error) agregar(raiz, await texto('Revisa este campo', 'ayuda', 'ColorScheme/error', 'ayuda'), { ancho: true });
  return raiz;
}

async function bannerError() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 320, pad: 'e12', radio: 'r8', fondo: 'ColorScheme/errorContainer' });
  agregar(f, await texto('No pudimos conectar con el servidor', 'cuerpo', 'ColorScheme/onErrorContainer', 'mensaje'), { ancho: true });
  return f;
}

const CHIPS = {
  disponible: ['ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer', 'Disponible'],
  reservado: ['ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer', 'Reservado'],
  reservadoPorTi: ['ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer', 'Reservado por ti'],
  intercambiado: ['ColorScheme/tertiaryContainer', 'ColorScheme/onTertiaryContainer', 'Intercambiado'],
  acordado: ['ColorScheme/primary', 'ColorScheme/onPrimary', 'Intercambio acordado'],
  noDisponible: ['ColorScheme/surfaceContainerHighest', 'ColorScheme/onSurfaceVariant', 'No disponible'],
};

async function chipEstado(c) {
  const d = CHIPS[c.Estado];
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', pad: ['e4', 'e10'], radio: 'r20', fondo: d[0], cruz: 'CENTER' });
  f.appendChild(await texto(d[2], 'chipDestacado', d[1], 'texto'));
  return f;
}

const TONOS = {
  primario: ['ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer'],
  secundario: ['ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer'],
  terciario: ['ColorScheme/tertiaryContainer', 'ColorScheme/onTertiaryContainer'],
};

async function etiqueta(c) {
  const d = TONOS[c.Tono];
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', pad: ['e4', 'e10'], gap: 'e4', radio: 'r16', fondo: d[0], cruz: 'CENTER' });
  f.appendChild(await glifo('◆', d[1], 'chip'));
  f.appendChild(await texto('Libros', 'etiqueta', d[1], 'texto'));
  return f;
}

async function estrellas(c) {
  const interactivo = c.Modo === 'interactivo';
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', pad: interactivo ? null : 'e4', gap: interactivo ? 'e2' : null, cruz: 'CENTER' });
  for (let i = 1; i <= 5; i++) {
    const g = await glifo(i <= Number(c.Puntaje) ? '★' : '☆', 'ColorScheme/secondary', 'subtitulo');
    if (interactivo) {
      const boton = marco({ nombre: 'estrella-' + i, dir: 'H', ancho: 40, alto: 40, radio: 'r20', alinea: 'CENTER', cruz: 'CENTER' });
      boton.appendChild(g);
      f.appendChild(boton);
    } else {
      f.appendChild(g);
    }
  }
  return f;
}

async function fotoPublicacion(c) {
  const fondos = {
    vacia: 'ColorScheme/surfaceContainerHighest',
    imagen: 'ColorScheme/primaryContainer',
    error: 'ColorScheme/surfaceContainerHighest',
  };
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: c.Forma === 'cuadrada' ? 140 : 280, alto: 140,
    radio: 'r12', fondo: fondos[c.Estado], alinea: 'CENTER', cruz: 'CENTER', recorta: true,
  });
  if (c.Estado === 'vacia') f.appendChild(await glifo('▣', 'ColorScheme/outline', 'titulo'));
  if (c.Estado === 'imagen') f.appendChild(await texto('Foto', 'cuerpo', 'ColorScheme/onPrimaryContainer', 'foto'));
  if (c.Estado === 'error') f.appendChild(await glifo('⚠', 'ColorScheme/outline', 'titulo'));
  return f;
}

async function mensajeVacio(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'V', ancho: 320, pad: 'e32', gap: 'e16', cruz: 'CENTER' });
  f.appendChild(await glifo('▣', 'ColorScheme/outline', 'titulo'));
  const titulo = await texto('Aún no hay publicaciones', 'subtitulo', 'ColorScheme/onSurface', 'titulo');
  titulo.textAlignHorizontal = 'CENTER';
  agregar(f, titulo, { ancho: true });
  const mensaje = await texto('Publica un objeto para empezar a intercambiar', 'cuerpo', 'ColorScheme/onSurface', 'mensaje');
  mensaje.textAlignHorizontal = 'CENTER';
  agregar(f, mensaje, { ancho: true });
  if (c.ConBoton === 'si') {
    agregar(f, cambiarTexto(instancia('BotonCarga', { Estado: 'default', Variante: 'primario' }), 'Publicar objeto'), { ancho: true });
  }
  return f;
}

async function errorConReintento() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'V', ancho: 320, pad: 'e24', gap: 'e16' });
  agregar(f, instancia('BannerError', { Estado: 'default' }), { ancho: true });
  agregar(f, cambiarTexto(instancia('BotonCarga', { Estado: 'default', Variante: 'tonal' }), 'Reintentar'), { ancho: true });
  return f;
}

async function filtrosFeed(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'V', ancho: 350, pad: ['e12', 'e20'], gap: 'e8' });
  const buscador = marco({
    nombre: 'buscador', dir: 'H', alto: 48, pad: [null, 'e12'], gap: 'e8', radio: 'r28',
    fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
  });
  buscador.appendChild(await glifo('⌕', 'ColorScheme/outline', 'tituloItem'));
  agregar(buscador, await texto('Buscar objetos', 'cuerpo', 'ColorScheme/outline', 'busqueda'), { ancho: true });
  buscador.appendChild(await glifo('→', 'ColorScheme/onSurfaceVariant', 'tituloItem'));
  agregar(f, buscador, { ancho: true });

  const menus = marco({ nombre: 'menus', dir: 'H', gap: 'e8' });
  for (const nombre of ['Categoría', 'Condición', 'Disponibilidad']) {
    const chip = marco({
      nombre: nombre, dir: 'H', pad: ['e4', 'e12'], gap: 'e4', radio: 'r28',
      fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
    });
    chip.appendChild(await glifo('≡', 'ColorScheme/onSurface', 'chip'));
    chip.appendChild(await texto(nombre, 'etiqueta', 'ColorScheme/onSurface', 'texto'));
    menus.appendChild(chip);
  }
  agregar(f, menus);

  if (c.Estado === 'conFiltros') {
    const activos = marco({ nombre: 'activos', dir: 'H', gap: 'e8', cruz: 'CENTER' });
    for (const contenido of ['Categoría: Libros', 'Condición: Usado']) {
      const chip = marco({
        nombre: contenido, dir: 'H', pad: ['e4', 'e8'], gap: 'e4', radio: 'r8',
        fondo: 'ColorScheme/surfaceContainerHighest', cruz: 'CENTER',
      });
      chip.appendChild(await texto(contenido, 'etiqueta', 'ColorScheme/onSurface', 'texto'));
      chip.appendChild(await glifo('✕', 'ColorScheme/onSurfaceVariant', 'chip'));
      activos.appendChild(chip);
    }
    activos.appendChild(await texto('Quitar todos', 'etiqueta', 'ColorScheme/primary', 'quitar'));
    agregar(f, activos);
  }
  return f;
}

const TARJETAS = {
  disponible: { chip: 'disponible', autor: 'Por: Ana Pérez', borde: 'ColorScheme/outlineVariant' },
  reservadoPorMi: { chip: 'reservadoPorTi', autor: 'Por: Ana Pérez', borde: 'ColorScheme/primary', grosor: 2 },
  reservadoPorOtro: { chip: 'reservado', autor: 'Por: Ana Pérez', borde: 'ColorScheme/outlineVariant', reserva: 'Reservado por: Luis' },
  propia: { chip: 'disponible', autor: 'Publicado por ti', borde: 'ColorScheme/outlineVariant', propia: true },
  ofertaEnviada: { chip: 'disponible', autor: 'Por: Ana Pérez', borde: 'ColorScheme/outlineVariant' },
  intercambiado: { chip: 'intercambiado', autor: 'Por: Ana Pérez', borde: 'ColorScheme/outlineVariant' },
};

function boton(contenido, variante, estado) {
  return cambiarTexto(instancia('BotonCarga', { Estado: estado || 'default', Variante: variante }), contenido);
}

async function tarjetaFeed(c) {
  const d = TARJETAS[c.Estado];
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'V', ancho: 350, pad: 'e16', gap: 'e10', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: d.borde, grosor: d.grosor,
  });
  agregar(f, instancia('FotoPublicacion', { Estado: 'vacia', Forma: 'ancha' }), { ancho: true });

  const cabecera = marco({ nombre: 'cabecera', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  agregar(cabecera, await texto('Calculadora científica', 'tituloTarjeta', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  cabecera.appendChild(instancia('ChipEstado', { Estado: d.chip }));
  agregar(f, cabecera, { ancho: true });

  const autor = marco({ nombre: 'autor', dir: 'H', gap: 'e4', cruz: 'CENTER' });
  autor.appendChild(await glifo('☺', 'ColorScheme/outline', 'chip'));
  autor.appendChild(await texto(d.autor, 'etiqueta', d.propia ? 'ColorScheme/primary' : 'ColorScheme/outline', 'autor'));
  agregar(f, autor);

  agregar(f, await texto('Casi nueva, incluye funda y manual.', 'detalle', 'ColorScheme/onSurfaceVariant', 'descripcion'), { ancho: true });

  const datos = marco({ nombre: 'datos', dir: 'H', gap: 'e6', cruz: 'CENTER' });
  datos.appendChild(await mini('Condición: Usado', 'ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer'));
  datos.appendChild(await mini('Categoría: Electrónica', 'ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer'));
  if (d.reserva) datos.appendChild(await mini(d.reserva, 'ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer'));
  agregar(f, datos);

  const acciones = marco({ nombre: 'acciones', dir: 'V', gap: 'e6' });
  agregar(f, acciones, { ancho: true });
  if (c.Estado === 'disponible') {
    agregar(acciones, boton('Ofrecer un objeto', 'primario'), { ancho: true });
    agregar(acciones, boton('Reservar', 'contorno'), { ancho: true });
    agregar(acciones, await texto('Ofrecer: cambias un objeto tuyo. Reservar: solo lo apartas.', 'pie', 'ColorScheme/outline', 'pie'), { ancho: true });
  }
  if (c.Estado === 'reservadoPorMi') {
    agregar(acciones, boton('Completar intercambio', 'primario'), { ancho: true });
    const fila = marco({ nombre: 'fila', dir: 'H', gap: 'e8' });
    agregar(acciones, fila, { ancho: true });
    agregar(fila, boton('WhatsApp', 'contorno'), { ancho: true });
    agregar(fila, boton('Cancelar reserva', 'contorno'), { ancho: true });
  }
  if (c.Estado === 'reservadoPorOtro') agregar(acciones, boton('Reservado', 'tonal', 'deshabilitado'), { ancho: true });
  if (c.Estado === 'propia') agregar(acciones, boton('Ver en mis publicaciones', 'contorno'), { ancho: true });
  if (c.Estado === 'ofertaEnviada') {
    agregar(acciones, boton('Oferta enviada', 'tonal', 'deshabilitado'), { ancho: true });
    agregar(acciones, boton('Ver mis ofertas', 'contorno'), { ancho: true });
  }
  if (c.Estado === 'intercambiado') agregar(acciones, boton('Intercambio completado', 'tonal', 'deshabilitado'), { ancho: true });
  return f;
}

async function tarjetaMiPublicacion(c) {
  const reservada = c.Reservada === 'si';
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'V', ancho: 350, pad: 'e16', gap: 'e12', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: reservada ? 'ColorScheme/primary' : 'ColorScheme/outlineVariant',
  });
  agregar(f, instancia('FotoPublicacion', { Estado: 'vacia', Forma: 'ancha' }), { ancho: true });

  const cabecera = marco({ nombre: 'cabecera', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  agregar(cabecera, await texto('Calculadora científica', 'tituloTarjeta', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  if (!reservada) cabecera.appendChild(await glifo('✎', 'ColorScheme/primary', 'tituloItem'));
  agregar(f, cabecera, { ancho: true });

  agregar(f, await texto('Casi nueva, incluye funda y manual.', 'detalle', 'ColorScheme/onSurfaceVariant', 'descripcion'), { ancho: true });

  const datos = marco({ nombre: 'datos', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  datos.appendChild(instancia('Etiqueta', { Tono: 'primario' }));
  datos.appendChild(instancia('ChipEstado', { Estado: reservada ? 'reservado' : 'disponible' }));
  agregar(f, datos);

  if (reservada) {
    agregar(f, await texto('Reservado por: Luis Gómez', 'detalle', 'ColorScheme/onSurfaceVariant', 'reserva'), { ancho: true });
    agregar(f, boton('Completar intercambio', 'primario'), { ancho: true });
  }
  return f;
}

async function encabezadoAcceso(c) {
  const conLogo = c.ConLogo === 'si';
  const f = marco({ nombre: 'raiz', componente: true, dir: 'V', ancho: 390, pad: ['e16', 'e24', 'e32', 'e24'], gap: 'e4', cruz: conLogo ? 'CENTER' : 'MIN' });
  radio(f, 'r36', ['bottomLeftRadius', 'bottomRightRadius']);
  try {
    f.fills = [degradado('TemaTruequeU/azulOscuro', 'TemaTruequeU/azul')];
    const lectura = f.fills[0] && f.fills[0].gradientStops && f.fills[0].gradientStops[0].boundVariables;
    if (!lectura || !lectura.color) f.fills = [pintura('ColorScheme/onPrimaryContainer')];
  } catch (e) {
    f.fills = [pintura('ColorScheme/onPrimaryContainer')];
  }
  if (conLogo) {
    f.appendChild(instancia('LogoTruequeU', { Variante: 'icono' }));
  } else {
    f.appendChild(await glifo('←', 'ColorScheme/onPrimary', 'subtitulo'));
  }
  const titulo = await texto('Iniciar sesión', 'titulo', 'ColorScheme/onPrimary', 'titulo');
  const subtitulo = await texto('Bienvenido de vuelta', 'cuerpo', 'ColorScheme/primaryContainer', 'subtitulo');
  if (conLogo) {
    titulo.textAlignHorizontal = 'CENTER';
    subtitulo.textAlignHorizontal = 'CENTER';
  }
  agregar(f, titulo, { ancho: true });
  agregar(f, subtitulo, { ancho: true });
  return f;
}

const DESTINOS = [
  ['explorar', '⌖', 'Explorar'],
  ['misPublicaciones', '▤', 'Mis publicaciones'],
  ['ofertas', '⇄', 'Ofertas'],
  ['perfil', '☺', 'Perfil'],
];

async function estructuraPrincipal(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, alto: 80, pad: ['e12', 'e8'], gap: 'e8', fondo: 'TemaTruequeU/blanco', cruz: 'CENTER' });
  for (const d of DESTINOS) {
    const activo = d[0] === c.Activo;
    const destino = marco({ nombre: d[0], dir: 'V', gap: 'e4', alinea: 'CENTER', cruz: 'CENTER' });
    const pastilla = marco({
      nombre: 'indicador', dir: 'H', ancho: 64, alto: 32, radio: 'r16',
      fondo: activo ? 'ColorScheme/primaryContainer' : null, alinea: 'CENTER', cruz: 'CENTER',
    });
    pastilla.appendChild(await glifo(d[1], activo ? 'ColorScheme/onPrimaryContainer' : 'ColorScheme/onSurfaceVariant', 'tituloItem'));
    destino.appendChild(pastilla);
    destino.appendChild(await texto(d[2], 'pie', activo ? 'ColorScheme/onSurface' : 'ColorScheme/onSurfaceVariant', 'texto'));
    agregar(f, destino, { ancho: true });
  }
  return f;
}

function tp(contenido, estilo, alineacion) {
  const inst = instancia('TextoPantalla', { Estilo: estilo || 'cuerpo', Alineacion: alineacion || 'izquierda' });
  return cambiarTexto(inst, contenido);
}

function ocultar(inst, nombre) {
  const n = inst.findOne(x => x.name === nombre);
  if (n) n.visible = false;
  return inst;
}

function filaBotones(padre, hijos) {
  const f = marco({ nombre: 'fila', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  agregar(padre, f, { ancho: true });
  hijos.forEach(h => agregar(f, h, { ancho: true }));
  return f;
}

const ESTILOS_TEXTO = {
  titulo: ['titulo', 'ColorScheme/onSurface'],
  subtitulo: ['subtitulo', 'ColorScheme/onSurface'],
  cuerpo: ['cuerpo', 'ColorScheme/onSurface'],
  negrita: ['tituloItem', 'ColorScheme/onSurface'],
  suave: ['cuerpo', 'ColorScheme/onSurfaceVariant'],
  ayuda: ['ayuda', 'ColorScheme/onSurfaceVariant'],
  error: ['ayuda', 'ColorScheme/error'],
  enlace: ['cuerpo', 'ColorScheme/primary'],
};
const ALINEACIONES = { izquierda: 'LEFT', centro: 'CENTER', derecha: 'RIGHT' };

async function textoPantalla(c) {
  const d = ESTILOS_TEXTO[c.Estilo];
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350 });
  const t = await texto('Texto de la pantalla', d[0], d[1], 'texto');
  t.textAlignHorizontal = ALINEACIONES[c.Alineacion];
  agregar(f, t, { ancho: true });
  return f;
}

async function divisor() {
  return marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, alto: 1, fondo: 'ColorScheme/outlineVariant' });
}

async function appBar(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 390, alto: 56, pad: [null, 'e16'], gap: 'e16',
    fondo: 'ColorScheme/surface', cruz: 'CENTER',
  });
  if (c.Volver === 'si') f.appendChild(await glifo('←', 'TemaTruequeU/azulOscuro', 'subtitulo'));
  agregar(f, await texto('Título de la pantalla', 'subtitulo', 'TemaTruequeU/azulOscuro', 'titulo'), { ancho: true });
  if (c.Accion === 'refrescar') f.appendChild(await glifo('⟳', 'TemaTruequeU/azulOscuro', 'tituloItem'));
  return f;
}

async function botonFlotante() {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', alto: 56, pad: [null, 'e20'], gap: 'e8', radio: 'r28',
    fondo: 'ColorScheme/secondary', alinea: 'CENTER', cruz: 'CENTER',
  });
  f.appendChild(await glifo('+', 'ColorScheme/onSecondary', 'tituloItem'));
  f.appendChild(await texto('Publicar', 'cuerpo', 'ColorScheme/onSecondary', 'texto'));
  return f;
}

async function snackBar() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, pad: 'e16', fondo: 'ColorScheme/onSurface', cruz: 'CENTER' });
  agregar(f, await texto('Contraseña actualizada.', 'cuerpo', 'ColorScheme/surface', 'texto'), { ancho: true });
  return f;
}

async function circleAvatar(c) {
  const grande = c.Tamano === 'grande';
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: grande ? 72 : 22, alto: grande ? 72 : 22, radio: grande ? 'r36' : 'r12',
    fondo: grande ? 'ColorScheme/primary' : 'ColorScheme/primaryContainer', alinea: 'CENTER', cruz: 'CENTER',
  });
  if (grande) f.appendChild(await texto('AP', 'titulo', 'ColorScheme/onPrimary', 'texto'));
  else f.appendChild(await texto('1', 'ayuda', 'ColorScheme/onPrimaryContainer', 'texto'));
  return f;
}

async function indicadorCarga(c) {
  const grande = c.Tamano === 'grande';
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: grande ? 'e40' : 'e8', alinea: 'CENTER', cruz: 'CENTER' });
  const giro = figma.createEllipse();
  giro.name = 'cargando';
  giro.resize(grande ? 36 : 28, grande ? 36 : 28);
  giro.fills = [];
  giro.strokes = [pintura('ColorScheme/primary')];
  giro.strokeWeight = grande ? 4 : 2;
  giro.arcData = { startingAngle: 0, endingAngle: Math.PI * 1.5, innerRadius: 0 };
  f.appendChild(giro);
  return f;
}

async function campoSelector(c) {
  const enfocado = c.Estado === 'enfocado';
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, alto: 56, pad: [null, 'e16'], gap: 'e12', radio: 'r14',
    fondo: 'TemaTruequeU/blanco', borde: enfocado ? 'ColorScheme/primary' : 'ColorScheme/outlineVariant',
    grosor: enfocado ? 2 : 1, cruz: 'CENTER',
  });
  const textos = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(textos, await texto('Estado del objeto', 'ayuda', 'ColorScheme/onSurfaceVariant', 'etiqueta'), { ancho: true });
  agregar(textos, await texto('Nuevo', 'cuerpo', 'ColorScheme/onSurface', 'valor'), { ancho: true });
  agregar(f, textos, { ancho: true });
  f.appendChild(await glifo('▾', 'ColorScheme/onSurfaceVariant', 'cuerpo'));
  return f;
}

async function iconoCaja() {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 56, alto: 56, radio: 'r16',
    fondo: 'ColorScheme/primaryContainer', alinea: 'CENTER', cruz: 'CENTER',
  });
  f.appendChild(await glifo('⚿', 'ColorScheme/primary', 'tituloItem'));
  return f;
}

async function bannerExito() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: 'e16', gap: 'e12', radio: 'r14', fondo: 'ColorScheme/tertiaryContainer', cruz: 'CENTER' });
  f.appendChild(await glifo('✓', 'ColorScheme/onTertiaryContainer', 'tituloItem'));
  agregar(f, await texto('Listo. Revisa tu correo: ahí está tu contraseña nueva.', 'cuerpo', 'ColorScheme/onTertiaryContainer', 'mensaje'), { ancho: true });
  return f;
}

async function pieEnlace(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, pad: [null, null, 'e16', null], gap: 'e4', alinea: 'CENTER', cruz: 'CENTER' });
  const crear = c.Variante === 'crearCuenta';
  f.appendChild(await texto(crear ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?', 'cuerpo', 'ColorScheme/onSurface', 'pregunta'));
  f.appendChild(await texto(crear ? 'Crear cuenta' : 'Inicia sesión', 'tituloItem', crear ? 'ColorScheme/secondary' : 'ColorScheme/primary', 'enlace'));
  return f;
}

async function cabeceraFeed() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, pad: ['e16', 'e8', null, 'e20'], gap: 'e8', cruz: 'CENTER' });
  const columna = marco({ nombre: 'saludo', dir: 'V', gap: 'e2' });
  agregar(columna, await texto('Hola, Ana', 'cuerpo', 'ColorScheme/onSurface', 'saludo'), { ancho: true });
  agregar(columna, await texto('¿Qué quieres intercambiar hoy?', 'subtitulo', 'ColorScheme/onSurface', 'pregunta'), { ancho: true });
  agregar(f, columna, { ancho: true });
  for (const g of ['?', '⟳']) {
    const b = marco({ nombre: 'boton', dir: 'H', ancho: 40, alto: 40, alinea: 'CENTER', cruz: 'CENTER' });
    b.appendChild(await glifo(g, 'ColorScheme/onSurfaceVariant', 'tituloItem'));
    f.appendChild(b);
  }
  return f;
}

async function segmentado(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, alto: 40, radio: 'r28', fondo: 'TemaTruequeU/blanco',
    borde: 'ColorScheme/outline', recorta: true,
  });
  const segmentos = [['recibidas', '↓', 'Recibidas'], ['enviadas', '↑', 'Enviadas']];
  for (const s of segmentos) {
    const activo = s[0] === c.Seleccionado;
    const color = activo ? 'ColorScheme/onPrimaryContainer' : 'ColorScheme/onSurface';
    const seg = marco({
      nombre: 'segmento-' + s[0], dir: 'H', gap: 'e8', fondo: activo ? 'ColorScheme/primaryContainer' : null,
      alinea: 'CENTER', cruz: 'CENTER',
    });
    seg.appendChild(await glifo(activo ? '✓' : s[1], color, 'cuerpo'));
    seg.appendChild(await texto(s[2], 'cuerpo', color, s[0]));
    agregar(f, seg, { ancho: true, alto: true });
  }
  return f;
}

async function filaLista(c) {
  const error = c.Tono === 'error';
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: ['e8', 'e16'], gap: 'e16', cruz: 'CENTER' });
  if (c.Icono === 'si') f.appendChild(await glifo('◆', error ? 'ColorScheme/error' : 'ColorScheme/primary', 'tituloItem'));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(columna, await texto('Intercambios completados', 'cuerpo', error ? 'ColorScheme/error' : 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  if (c.Subtitulo === 'si') agregar(columna, await texto('Subtítulo', 'detalle', 'ColorScheme/onSurfaceVariant', 'subtitulo'), { ancho: true });
  agregar(f, columna, { ancho: true });
  if (c.Final === 'chevron') f.appendChild(await texto('›', 'tituloItem', 'ColorScheme/onSurfaceVariant', 'chevron'));
  return f;
}

async function resumenCalificaciones(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, alto: c.Estado === 'cargando' ? 24 : null, gap: 'e6',
    alinea: 'CENTER', cruz: 'CENTER',
  });
  if (c.Estado === 'vacio') {
    const t = await texto('Aún no tienes calificaciones', 'cuerpo', 'ColorScheme/onSurface', 'texto');
    t.textAlignHorizontal = 'CENTER';
    agregar(f, t, { ancho: true });
  }
  if (c.Estado === 'conDatos') {
    f.appendChild(await glifo('☆', 'ColorScheme/secondary', 'tituloItem'));
    f.appendChild(await texto('4.5 de 5 · 12 calificaciones', 'cuerpo', 'ColorScheme/onSurface', 'texto'));
  }
  return f;
}

function bloqueBase(titulo) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'V', ancho: 318, pad: 'e12', gap: 'e6', radio: 'r12',
    fondo: 'ColorScheme/surfaceContainerHighest',
  });
  agregar(f, tp(titulo, 'negrita'), { ancho: true });
  return f;
}

async function bloqueCalificacion(c) {
  const f = bloqueBase('Calificación');
  if (c.Estado === 'sinCalificar') {
    agregar(f, tp('Todavía no calificas a Luis Gómez'), { ancho: true });
    agregar(f, boton('Calificar', 'contorno'), { ancho: true });
  } else {
    agregar(f, tp('Calificaste a Luis Gómez: 4 de 5', 'negrita'), { ancho: true });
    f.appendChild(instancia('Estrellas', { Puntaje: '4', Modo: 'lectura' }));
    agregar(f, tp('"Muy puntual y amable"'), { ancho: true });
  }
  return f;
}

const ENTREGA_ACORDADA = '15/06/2030 a las 15:30 en Biblioteca central';
const ENTREGA_PROPUESTA = '16/06/2030 a las 10:00 en Cafetería';

async function bloqueEntrega(c) {
  const f = bloqueBase('Fecha y lugar de entrega');
  const vigente = c.Estado === 'acuerdoVigente' || c.Estado === 'reprogramando';
  agregar(f, tp(vigente ? 'Acordado: ' + ENTREGA_ACORDADA : 'Todavía no acordaron fecha ni lugar', vigente ? 'negrita' : 'cuerpo'), { ancho: true });
  if (c.Estado === 'sinAcuerdo') agregar(f, boton('Proponer fecha y lugar', 'contorno'), { ancho: true });
  if (c.Estado === 'acuerdoVigente') agregar(f, boton('Reprogramar', 'contorno'), { ancho: true });
  if (c.Estado === 'propuestaPendiente' || c.Estado === 'reprogramando') {
    const cambio = c.Estado === 'reprogramando';
    agregar(f, tp('Luis Gómez ' + (cambio ? 'propone cambiar a' : 'propone') + ': ' + ENTREGA_PROPUESTA), { ancho: true });
    if (cambio) agregar(f, tp('Mientras tanto sigue vigente el acuerdo anterior.'), { ancho: true });
    filaBotones(f, [boton('Aceptar propuesta', 'primario'), boton('Contraproponer', 'contorno')]);
  }
  if (c.Estado !== 'sinAcuerdo') agregar(f, tp('Historial de entrega', 'enlace', 'derecha'), { ancho: true });
  return f;
}

async function chipMaterial(contenido, caracter) {
  const f = marco({ nombre: 'chip', dir: 'H', pad: ['e4', 'e8'], gap: 'e4', radio: 'r8', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER' });
  if (caracter) f.appendChild(await glifo(caracter, 'ColorScheme/onSurface', 'chip'));
  f.appendChild(await texto(contenido, 'etiqueta', 'ColorScheme/onSurface', 'texto'));
  return f;
}

function tarjetaBase(gap) {
  return marco({
    nombre: 'raiz', componente: true, dir: 'V', ancho: 350, pad: 'e16', gap: gap || 'e8', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant',
  });
}

async function tarjetaIntercambio(c) {
  const f = tarjetaBase('e6');
  agregar(f, await texto('Calculadora científica', 'tituloTarjeta', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  const entregue = c.Rol === 'entregue';
  agregar(f, await texto(entregue ? 'Lo entregaste a: Luis Gómez' : 'Lo recibiste de: Ana Pérez', 'cuerpo', 'ColorScheme/onSurfaceVariant', 'quien'), { ancho: true });
  const chips = marco({ nombre: 'chips', dir: 'H', gap: 'e8' });
  chips.appendChild(await chipMaterial('Categoría: Electrónica'));
  chips.appendChild(await chipMaterial('Intercambiado', '✓'));
  agregar(f, chips);
  return f;
}

const ESTADOS_OFERTA = {
  pendiente: ['ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer', 'Pendiente'],
  contraofertada: ['ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer', 'Contraofertada'],
  aceptada: ['ColorScheme/tertiaryContainer', 'ColorScheme/onTertiaryContainer', 'Aceptada'],
  completada: ['ColorScheme/tertiaryContainer', 'ColorScheme/onTertiaryContainer', 'Intercambio completado'],
  anulada: ['ColorScheme/errorContainer', 'ColorScheme/onErrorContainer', 'Intercambio cancelado'],
  rechazada: ['ColorScheme/errorContainer', 'ColorScheme/onErrorContainer', 'Rechazada'],
  cancelada: ['ColorScheme/surfaceContainerHighest', 'ColorScheme/onSurfaceVariant', 'Cancelada'],
};

async function chipEstadoOferta(c) {
  const d = ESTADOS_OFERTA[c.Estado];
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', pad: ['e4', 'e10'], radio: 'r20', fondo: d[0], cruz: 'CENTER' });
  f.appendChild(await texto(d[2], 'etiqueta', d[1], 'texto'));
  return f;
}

async function tarjetaOferta(c) {
  const recibida = c.Lado === 'recibida';
  const f = tarjetaBase('e8');
  const cabecera = marco({ nombre: 'cabecera', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  cabecera.appendChild(instancia('ChipEstadoOferta', { Estado: c.Estado }));
  const quien = await texto(recibida ? 'De: Luis Gómez' : 'Para: Ana Pérez', 'cuerpo', 'ColorScheme/onSurfaceVariant', 'quien');
  quien.textAlignHorizontal = 'RIGHT';
  agregar(cabecera, quien, { ancho: true });
  agregar(f, cabecera, { ancho: true });
  agregar(f, tp('Ronda 1', 'suave'), { ancho: true });
  agregar(f, tp('Quiere: Calculadora científica'), { ancho: true });
  agregar(f, tp('Ofrece: Mochila azul', 'negrita'), { ancho: true });
  if (c.Estado === 'pendiente') {
    if (recibida) {
      filaBotones(f, [boton('Aceptar', 'primario'), boton('Rechazar', 'contorno')]);
      agregar(f, boton('Contraofertar', 'contorno'), { ancho: true });
    } else {
      agregar(f, boton('Cancelar oferta', 'contorno'), { ancho: true });
    }
  }
  if (c.Estado === 'aceptada') {
    agregar(f, instancia('BloqueEntrega', { Estado: 'acuerdoVigente' }), { ancho: true });
    agregar(f, tp('Tu entrega: pendiente'), { ancho: true });
    agregar(f, tp('La otra persona: confirmada'), { ancho: true });
    agregar(f, boton('Confirmar entrega', 'primario'), { ancho: true });
    agregar(f, boton('Cancelar intercambio', 'contornoRojo'), { ancho: true });
  }
  if (c.Estado === 'completada') {
    agregar(f, instancia('BloqueCalificacion', { Estado: recibida ? 'sinCalificar' : 'calificado' }), { ancho: true });
  }
  if (c.Estado === 'anulada' || c.Estado === 'cancelada') {
    agregar(f, tp('Motivo: No pude asistir a la cita'), { ancho: true });
  }
  agregar(f, tp('Ver historial', 'enlace', 'derecha'), { ancho: true });
  return f;
}

async function filtrosHistorial(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, gap: 'e8' });
  for (const d of [['todo', 'Todo'], ['reservas', 'Reservas'], ['completados', 'Completados']]) {
    const activo = d[0] === c.Seleccionado;
    const chip = marco({
      nombre: d[0], dir: 'H', pad: ['e6', 'e12'], radio: 'r8', cruz: 'CENTER',
      fondo: activo ? 'ColorScheme/secondaryContainer' : null, borde: activo ? null : 'ColorScheme/outlineVariant',
    });
    chip.appendChild(await texto(d[1], 'cuerpo', activo ? 'ColorScheme/onSecondaryContainer' : 'ColorScheme/onSurface', 'texto'));
    f.appendChild(chip);
  }
  return f;
}

const MOVIMIENTOS = {
  reservo: ['⚐', 'Reservaste «Calculadora científica» de Luis Gómez', 'Reservado · 20 oct'],
  canceloReserva: ['⊘', 'Luis Gómez canceló su reserva de «Calculadora científica»', 'Reserva cancelada · 18 oct'],
  completo: ['✓', 'Completaste el intercambio de «Calculadora científica» con Luis Gómez', 'Completado · 15 oct'],
};

async function tarjetaHistorial(c) {
  const d = MOVIMIENTOS[c.Tipo];
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: 'e16', gap: 'e12', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
  });
  f.appendChild(await glifo(d[0], 'ColorScheme/onSurface', 'titulo'));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e4' });
  agregar(columna, await texto(d[1], 'tituloItem', 'ColorScheme/onSurface', 'frase'), { ancho: true });
  agregar(columna, await texto(d[2], 'cuerpo', 'ColorScheme/onSurfaceVariant', 'estado'), { ancho: true });
  agregar(f, columna, { ancho: true });
  f.appendChild(await texto('›', 'tituloItem', 'ColorScheme/onSurfaceVariant', 'chevron'));
  return f;
}

async function tarjetaAviso(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: ['e8', 'e16'], gap: 'e16', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
  });
  f.appendChild(await glifo(c.Estado === 'noLeida' ? '◉' : '○', 'ColorScheme/primary', 'tituloItem'));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(columna, await texto('Luis Gómez aceptó tu oferta por «Calculadora científica»', 'cuerpo', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  agregar(columna, await texto('12/11/2026', 'detalle', 'ColorScheme/onSurfaceVariant', 'subtitulo'), { ancho: true });
  agregar(f, columna, { ancho: true });
  return f;
}

async function tarjetaDatos(c) {
  const f = tarjetaBase('e8');
  agregar(f, await texto('Tu perfil', 'tituloItem', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  agregar(f, await texto('Nombre: Ana Pérez\nCorreo: ana@universidad.edu', 'cuerpo', 'ColorScheme/onSurface', 'lineas'), { ancho: true });
  if (c.Variante === 'conAccion') agregar(f, tp('Quitar mi teléfono', 'enlace'), { ancho: true });
  return f;
}

async function dialogoBase(titulo, alto) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'V', ancho: 310, alto: alto, pad: 'e24', gap: 'e16', radio: 'r28',
    fondo: 'ColorScheme/surface', recorta: !!alto,
  });
  agregar(f, await texto(titulo, 'titulo', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  return f;
}

async function dialogoConfirmar(c) {
  const destructivo = c.Variante === 'destructivo';
  const f = await dialogoBase(destructivo ? 'Rechazar oferta' : 'Aceptar trueque');
  agregar(f, tp(destructivo
    ? '¿Rechazas esta oferta? Quien la envió verá que fue rechazada.'
    : '¿Aceptas cambiar «Mochila azul» por «Calculadora científica»? Las dos publicaciones quedarán acordadas, cada uno confirmará la entrega y las otras ofertas pendientes de esos objetos se cancelarán.', 'suave'), { ancho: true });
  filaBotones(f, [boton('Cancelar', 'texto'), boton(destructivo ? 'Rechazar' : 'Aceptar', destructivo ? 'rojo' : 'primario')]);
  return f;
}

async function dialogoAyuda() {
  const f = await dialogoBase('¿Cómo funciona?', 700);
  const cuerpo = marco({ nombre: 'contenido', dir: 'V', gap: 'e8', recorta: true });
  agregar(f, cuerpo, { ancho: true, alto: true });
  const pasos = [
    ['1', 'Reservar: toca "Reservar" en un objeto disponible. Quedará apartado para ti.'],
    ['2', 'Coordinar: el teléfono del dueño aparece cuando los dos aceptan el trueque. Entonces puedes escribirle por WhatsApp para acordar lugar y hora.'],
    ['3', 'Entregar: encuéntrense y hagan el intercambio.'],
    ['4', 'Completar: toca "Completar intercambio" cuando ya se realizó.'],
  ];
  for (const p of pasos) {
    const paso = marco({ nombre: 'paso', dir: 'H', gap: 'e8' });
    paso.appendChild(cambiarTexto(instancia('CircleAvatar', { Tamano: 'chico' }), p[0]));
    agregar(paso, tp(p[1], 'suave'), { ancho: true });
    agregar(cuerpo, paso, { ancho: true });
  }
  agregar(cuerpo, tp('¿Te equivocaste? Usa "Cancelar reserva" y el objeto vuelve a estar disponible.', 'suave'), { ancho: true });
  agregar(cuerpo, tp('También puedes ofrecer uno de tus objetos: en una publicación disponible toca "Ofrecer un objeto". El dueño la acepta, la rechaza o responde con una contraoferta en Ofertas de trueque. Ofrecer cambia un objeto tuyo por el suyo; Reservar solo lo aparta. Cuando el intercambio se completa, cada parte puede calificar a la otra de 1 a 5 estrellas en Ofertas de trueque.', 'suave'), { ancho: true });
  agregar(cuerpo, tp('Estados', 'negrita'), { ancho: true });
  agregar(cuerpo, tp('• Disponible: se puede reservar.\n• Reservado: alguien lo apartó.\n• Intercambio acordado: se aceptó una oferta; acuerdan fecha y lugar, cada parte confirma la entrega y, si algo falla, cualquiera puede cancelar con un motivo.\n• No disponible: se ve, pero nadie puede reservarlo.\n• Oculta: solo la ve su dueño.\n• Intercambiado: el trueque ya se completó.', 'suave'), { ancho: true });
  agregar(f, boton('Entendido', 'primario'), { ancho: true });
  return f;
}

function campoDialogo(padre, contenidoCampo, estado, tipo, error) {
  const inst = instancia('CampoTexto', { Estado: estado, Tipo: tipo || 'texto', Icono: 'no' });
  cambiarTexto(inst, contenidoCampo);
  if (error) cambiarTexto(inst, error, 'ayuda');
  agregar(padre, inst, { ancho: true });
  return inst;
}

async function dialogoCalificacion(c) {
  const f = await dialogoBase('Calificar a Luis Gómez');
  const estrellasFila = marco({ nombre: 'estrellas', dir: 'H', alinea: 'CENTER' });
  estrellasFila.appendChild(instancia('Estrellas', { Puntaje: c.Estado === 'conPuntaje' ? '4' : '0', Modo: 'interactivo' }));
  agregar(f, estrellasFila, { ancho: true });
  if (c.Estado === 'error') agregar(f, tp('Elige de 1 a 5 estrellas', 'error', 'centro'), { ancho: true });
  campoDialogo(f, c.Estado === 'conPuntaje' ? 'Muy puntual y amable' : 'Comentario (opcional)', c.Estado === 'conPuntaje' ? 'relleno' : 'vacio', 'multilinea');
  agregar(f, tp(c.Estado === 'conPuntaje' ? '20/200' : '0/200', 'ayuda', 'derecha'), { ancho: true });
  filaBotones(f, [boton('Volver', 'texto'), boton('Enviar calificación', 'primario')]);
  return f;
}

async function dialogoMotivo(c) {
  const conMotivo = c.Estado === 'conMotivo';
  const f = await dialogoBase('Cancelar intercambio');
  agregar(f, tp('Las dos publicaciones volverán a estar disponibles. El motivo queda guardado en el historial.', 'suave'), { ancho: true });
  campoDialogo(f, conMotivo ? 'No pude asistir a la cita' : 'Motivo', conMotivo ? 'relleno' : 'vacio');
  agregar(f, tp(conMotivo ? '25/200' : '0/200', 'ayuda', 'derecha'), { ancho: true });
  filaBotones(f, [boton('Volver', 'texto'), boton('Sí, cancelar', 'primario', conMotivo ? 'default' : 'deshabilitado')]);
  return f;
}

const DIALOGOS_ENTREGA = {
  proponer: ['Proponer fecha y lugar', 'Enviar propuesta'],
  reprogramar: ['Reprogramar la entrega', 'Enviar reprogramación'],
  contraproponer: ['Contraproponer', 'Enviar contrapropuesta'],
  conErrores: ['Proponer fecha y lugar', 'Enviar propuesta'],
};

async function dialogoEntrega(c) {
  const d = DIALOGOS_ENTREGA[c.Variante];
  const conDatos = c.Variante === 'reprogramar' || c.Variante === 'contraproponer';
  const conErrores = c.Variante === 'conErrores';
  const f = await dialogoBase(d[0]);
  const campos = marco({ nombre: 'campos', dir: 'V', gap: 'e8' });
  agregar(f, campos, { ancho: true });
  const datos = [
    ['Fecha (dd/mm/aaaa)', '15/06/2030', 'Escribe una fecha válida, por ejemplo 15/06/2030'],
    ['Hora (hh:mm)', '15:30', 'Escribe una hora válida, por ejemplo 15:30'],
    ['Lugar', 'Biblioteca central', 'Escribe el lugar de la entrega'],
  ];
  for (const k of datos) {
    campoDialogo(campos, conDatos ? k[1] : k[0], conErrores ? 'error' : conDatos ? 'relleno' : 'vacio', 'texto', conErrores ? k[2] : null);
  }
  filaBotones(f, [boton('Volver', 'texto'), boton(d[1], 'primario')]);
  return f;
}

async function filaRadio(titulo, subtitulo, marcada) {
  const f = marco({ nombre: 'opcion', dir: 'H', gap: 'e12', cruz: 'CENTER' });
  f.appendChild(await glifo(marcada ? '◉' : '○', marcada ? 'ColorScheme/primary' : 'ColorScheme/onSurfaceVariant', 'tituloItem'));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(columna, await texto(titulo, 'cuerpo', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  agregar(columna, await texto(subtitulo, 'detalle', 'ColorScheme/onSurfaceVariant', 'subtitulo'), { ancho: true });
  agregar(f, columna, { ancho: true });
  return f;
}

async function dialogoOferta(c) {
  const ofrecer = c.Tipo === 'ofrecer';
  const vacio = c.Estado === 'vacio';
  const f = await dialogoBase(ofrecer ? 'Ofrecer un objeto' : 'Contraofertar');
  if (vacio) {
    agregar(f, tp(ofrecer
      ? 'No tienes publicaciones disponibles para ofrecer. Crea una y déjala en estado disponible.'
      : 'No hay otro objeto disponible para proponer en esta negociación.', 'suave'), { ancho: true });
  } else {
    agregar(f, tp(ofrecer
      ? '¿Qué objeto tuyo ofreces por «Calculadora científica»?'
      : '¿Qué otro objeto propones por «Calculadora científica»?', 'suave'), { ancho: true });
    const opciones = marco({ nombre: 'opciones', dir: 'V', gap: 'e8' });
    agregar(f, opciones, { ancho: true });
    agregar(opciones, await filaRadio('Mochila azul', 'Otros', true), { ancho: true });
    agregar(opciones, await filaRadio('Libro de cálculo', 'Libros', false), { ancho: true });
    agregar(opciones, await filaRadio('Chaqueta de lana', 'Ropa', false), { ancho: true });
  }
  const botones = [boton('Cancelar', 'texto')];
  if (vacio && ofrecer) botones.push(boton('Crear publicación', 'primario'));
  if (!vacio) botones.push(boton(ofrecer ? 'Enviar oferta' : 'Enviar contraoferta', 'primario'));
  filaBotones(f, botones);
  return f;
}

async function dialogoEditar(c) {
  const guardando = c.Estado === 'guardando';
  const f = await dialogoBase('Editar información');
  campoDialogo(f, 'Calculadora científica', 'relleno');
  campoDialogo(f, 'Casi nueva, incluye funda y manual.', 'relleno', 'multilinea');
  agregar(f, instancia('FotoPublicacion', { Estado: 'imagen', Forma: 'ancha' }), { ancho: true });
  agregar(f, boton('Cambiar foto', 'contorno', guardando ? 'deshabilitado' : 'default'), { ancho: true });
  agregar(f, boton('Quitar foto', 'texto', guardando ? 'deshabilitado' : 'default'), { ancho: true });
  if (c.Estado === 'error') {
    agregar(f, cambiarTexto(instancia('BannerError', { Estado: 'default' }), 'Ocurrió un error al actualizar la publicación', 'mensaje'), { ancho: true });
  }
  filaBotones(f, [boton('Cancelar', 'texto', guardando ? 'deshabilitado' : 'default'), boton('Guardar', 'primario', guardando ? 'cargando' : 'default')]);
  return f;
}

async function dialogoEliminarCuenta(c) {
  const error = c.Estado === 'error';
  const f = await dialogoBase('Eliminar cuenta');
  agregar(f, tp('Esto es lo que va a pasar:', 'suave'), { ancho: true });
  agregar(f, tp('• Tus trueques en curso se cancelan y se avisa a la otra persona.\n• Tus publicaciones dejan de mostrarse.\n• Tus calificaciones quedan sin tu nombre.\n• No se puede deshacer.', 'suave'), { ancho: true });
  campoDialogo(f, error ? '••••••••' : 'Tu contraseña', error ? 'error' : 'vacio', 'contrasena', error ? 'Contraseña incorrecta' : null);
  filaBotones(f, [boton('Cancelar', 'contorno'), boton('Eliminar cuenta', 'contornoRojo')]);
  return f;
}

async function dialogoHistorial(c) {
  const titulos = { negociacion: 'Historial de la negociación', entrega: 'Historial de entrega', movimiento: 'Calculadora científica' };
  const f = await dialogoBase(titulos[c.Tipo]);
  const lineas = {
    negociacion: [
      ['Se negocia: Calculadora científica', 'suave'],
      ['Ronda 1: Luis Gómez propone Mochila azul', 'negrita'], ['Contraofertada · 12/11 10:30', 'suave'],
      ['Ronda 2: Luis Gómez propone Libro de cálculo', 'negrita'], ['Aceptada · 12/11 18:05', 'suave'],
    ],
    entrega: [
      ['Luis Gómez propone: ' + ENTREGA_PROPUESTA, 'negrita'], ['Se respondió con otra propuesta', 'suave'],
      ['Ana Pérez propone: ' + ENTREGA_ACORDADA, 'negrita'], ['Acuerdo vigente', 'suave'],
    ],
    movimiento: [
      ['Reservaste «Calculadora científica» de Luis Gómez', 'suave'],
      ['◔ Estado: Reservado', 'suave'], ['Categoría: Electrónica', 'suave'], ['Con: Luis Gómez', 'suave'],
      ['Fecha: 20 oct 2026, 16:24', 'suave'],
    ],
  };
  const cuerpo = marco({ nombre: 'contenido', dir: 'V', gap: 'e8' });
  agregar(f, cuerpo, { ancho: true });
  lineas[c.Tipo].forEach(l => agregar(cuerpo, tp(l[0], l[1]), { ancho: true }));
  agregar(f, boton('Cerrar', 'primario'), { ancho: true });
  return f;
}

const DEFINICIONES = [
  { nombre: 'LogoTruequeU', props: { Variante: ['icono', 'conNombre'] }, construir: logo, textos: [] },
  {
    nombre: 'BotonCarga',
    props: { Estado: ['default', 'hover', 'presionado', 'cargando', 'deshabilitado'], Variante: ['primario', 'rojo', 'tonal', 'contorno', 'contornoRojo', 'texto'] },
    construir: botonCarga, textos: [['texto', 'texto', 'Continuar']], columnas: 5,
  },
  {
    nombre: 'CampoTexto',
    props: { Estado: ['vacio', 'enfocado', 'relleno', 'error', 'deshabilitado'], Tipo: ['texto', 'contrasena', 'multilinea'], Icono: ['no', 'si'] },
    construir: campoTexto, textos: [['texto', 'texto', 'Correo']], columnas: 5,
  },
  { nombre: 'BannerError', props: { Estado: ['default'] }, construir: bannerError, textos: [['mensaje', 'mensaje', 'Mensaje de error']] },
  {
    nombre: 'ChipEstado',
    props: { Estado: ['disponible', 'reservado', 'reservadoPorTi', 'intercambiado', 'acordado', 'noDisponible'] },
    construir: chipEstado, textos: [['texto', 'texto', 'Disponible']], columnas: 6,
  },
  { nombre: 'Etiqueta', props: { Tono: ['primario', 'secundario', 'terciario'] }, construir: etiqueta, textos: [['texto', 'texto', 'Libros']] },
  {
    nombre: 'Estrellas',
    props: { Puntaje: ['0', '1', '2', '3', '4', '5'], Modo: ['lectura', 'interactivo'] },
    construir: estrellas, textos: [], columnas: 6,
  },
  {
    nombre: 'FotoPublicacion',
    props: { Estado: ['vacia', 'imagen', 'error'], Forma: ['ancha', 'cuadrada'] },
    construir: fotoPublicacion, textos: [], columnas: 3,
  },
  {
    nombre: 'MensajeVacio', props: { ConBoton: ['si', 'no'] }, construir: mensajeVacio,
    textos: [['titulo', 'titulo', 'Aún no hay publicaciones'], ['mensaje', 'mensaje', 'Publica un objeto para empezar a intercambiar']],
  },
  { nombre: 'ErrorConReintento', props: { Estado: ['default'] }, construir: errorConReintento, textos: [] },
  { nombre: 'FiltrosFeed', props: { Estado: ['sinFiltros', 'conFiltros'] }, construir: filtrosFeed, textos: [] },
  {
    nombre: 'TarjetaFeed',
    props: { Estado: ['disponible', 'reservadoPorMi', 'reservadoPorOtro', 'propia', 'ofertaEnviada', 'intercambiado'] },
    construir: tarjetaFeed, textos: [['titulo', 'titulo', 'Calculadora científica']], columnas: 3,
  },
  {
    nombre: 'TarjetaMiPublicacion', props: { Reservada: ['no', 'si'] }, construir: tarjetaMiPublicacion,
    textos: [['titulo', 'titulo', 'Calculadora científica']],
  },
  {
    nombre: 'EncabezadoAcceso', props: { ConLogo: ['si', 'no'] }, construir: encabezadoAcceso,
    textos: [['titulo', 'titulo', 'Iniciar sesión'], ['subtitulo', 'subtitulo', 'Bienvenido de vuelta']],
  },
  {
    nombre: 'EstructuraPrincipal', props: { Activo: ['explorar', 'misPublicaciones', 'ofertas', 'perfil'] },
    construir: estructuraPrincipal, textos: [], columnas: 2,
  },
  {
    nombre: 'TextoPantalla',
    props: { Estilo: ['titulo', 'subtitulo', 'cuerpo', 'negrita', 'suave', 'ayuda', 'error', 'enlace'], Alineacion: ['izquierda', 'centro', 'derecha'] },
    construir: textoPantalla, textos: [['texto', 'texto', 'Texto de la pantalla']], columnas: 3,
  },
  { nombre: 'Divider', props: { Estado: ['default'] }, construir: divisor, textos: [] },
  {
    nombre: 'AppBar', props: { Volver: ['no', 'si'], Accion: ['ninguna', 'refrescar'] }, construir: appBar,
    textos: [['titulo', 'titulo', 'Título de la pantalla']],
  },
  {
    nombre: 'FloatingActionButton', props: { Variante: ['extendido'] }, construir: botonFlotante,
    textos: [['texto', 'texto', 'Publicar']],
  },
  { nombre: 'SnackBar', props: { Estado: ['default'] }, construir: snackBar, textos: [['texto', 'texto', 'Contraseña actualizada.']] },
  { nombre: 'CircleAvatar', props: { Tamano: ['grande', 'chico'] }, construir: circleAvatar, textos: [] },
  { nombre: 'CircularProgressIndicator', props: { Tamano: ['grande', 'pequeno'] }, construir: indicadorCarga, textos: [] },
  {
    nombre: 'DropdownButtonFormField', props: { Estado: ['default', 'enfocado'] }, construir: campoSelector,
    textos: [['etiqueta', 'etiqueta', 'Estado del objeto'], ['valor', 'valor', 'Nuevo']],
  },
  { nombre: 'IconoCaja', props: { Icono: ['llave'] }, construir: iconoCaja, textos: [] },
  {
    nombre: 'BannerExito', props: { Estado: ['default'] }, construir: bannerExito,
    textos: [['mensaje', 'mensaje', 'Listo. Revisa tu correo: ahí está tu contraseña nueva.']],
  },
  { nombre: 'PieEnlace', props: { Variante: ['crearCuenta', 'iniciarSesion'] }, construir: pieEnlace, textos: [] },
  { nombre: 'CabeceraFeed', props: { Estado: ['default'] }, construir: cabeceraFeed, textos: [['saludo', 'saludo', 'Hola, Ana']] },
  {
    nombre: 'SegmentedButton', props: { Seleccionado: ['recibidas', 'enviadas'] }, construir: segmentado,
    textos: [['recibidas', 'recibidas', 'Recibidas'], ['enviadas', 'enviadas', 'Enviadas']],
  },
  {
    nombre: 'FilaLista',
    props: { Icono: ['con', 'sin'], Subtitulo: ['con', 'sin'], Final: ['ninguno', 'chevron'], Tono: ['normal', 'error'] },
    construir: filaLista, textos: [['titulo', 'titulo', 'Intercambios completados'], ['subtitulo', 'subtitulo', 'Subtítulo']], columnas: 4,
  },
  { nombre: 'ResumenCalificaciones', props: { Estado: ['cargando', 'vacio', 'conDatos'] }, construir: resumenCalificaciones, textos: [] },
  { nombre: 'BloqueCalificacion', props: { Estado: ['sinCalificar', 'calificado'] }, construir: bloqueCalificacion, textos: [] },
  {
    nombre: 'BloqueEntrega', props: { Estado: ['sinAcuerdo', 'acuerdoVigente', 'propuestaPendiente', 'reprogramando'] },
    construir: bloqueEntrega, textos: [], columnas: 4,
  },
  { nombre: 'TarjetaIntercambio', props: { Rol: ['entregue', 'recibi'] }, construir: tarjetaIntercambio, textos: [['titulo', 'titulo', 'Calculadora científica']] },
  {
    nombre: 'ChipEstadoOferta',
    props: { Estado: ['pendiente', 'contraofertada', 'aceptada', 'completada', 'anulada', 'rechazada', 'cancelada'] },
    construir: chipEstadoOferta, textos: [], columnas: 4,
  },
  {
    nombre: 'TarjetaOferta',
    props: {
      Estado: ['pendiente', 'contraofertada', 'aceptada', 'completada', 'anulada', 'rechazada', 'cancelada'],
      Lado: ['recibida', 'enviada'],
    },
    construir: tarjetaOferta, textos: [], columnas: 4,
  },
  {
    nombre: 'FiltrosHistorial', props: { Seleccionado: ['todo', 'reservas', 'completados'] }, construir: filtrosHistorial, textos: [],
  },
  { nombre: 'TarjetaHistorial', props: { Tipo: ['reservo', 'canceloReserva', 'completo'] }, construir: tarjetaHistorial, textos: [] },
  {
    nombre: 'TarjetaAviso', props: { Estado: ['noLeida', 'leida'] }, construir: tarjetaAviso,
    textos: [['titulo', 'titulo', 'Luis Gómez aceptó tu oferta por «Calculadora científica»'], ['subtitulo', 'subtitulo', '12/11/2026']],
  },
  {
    nombre: 'TarjetaDatos', props: { Variante: ['normal', 'conAccion'] }, construir: tarjetaDatos,
    textos: [['titulo', 'titulo', 'Tu perfil'], ['lineas', 'lineas', 'Nombre: Ana Pérez\nCorreo: ana@universidad.edu']],
  },
  { nombre: 'confirmarAccion', props: { Variante: ['normal', 'destructivo'] }, construir: dialogoConfirmar, textos: [] },
  { nombre: 'mostrarAyudaTrueque', props: { Estado: ['default'] }, construir: dialogoAyuda, textos: [] },
  { nombre: 'pedirCalificacion', props: { Estado: ['sinPuntaje', 'conPuntaje', 'error'] }, construir: dialogoCalificacion, textos: [] },
  { nombre: 'pedirMotivoCancelacion', props: { Estado: ['vacio', 'conMotivo'] }, construir: dialogoMotivo, textos: [] },
  {
    nombre: 'pedirDatosEntrega', props: { Variante: ['proponer', 'reprogramar', 'contraproponer', 'conErrores'] },
    construir: dialogoEntrega, textos: [], columnas: 4,
  },
  {
    nombre: 'mostrarDialogoOferta', props: { Tipo: ['ofrecer', 'contraofertar'], Estado: ['conOpciones', 'vacio'] },
    construir: dialogoOferta, textos: [], columnas: 4,
  },
  { nombre: 'DialogoEditarPublicacion', props: { Estado: ['normal', 'guardando', 'error'] }, construir: dialogoEditar, textos: [] },
  { nombre: 'DialogoEliminarCuenta', props: { Estado: ['normal', 'error'] }, construir: dialogoEliminarCuenta, textos: [] },
  { nombre: 'DialogoHistorial', props: { Tipo: ['negociacion', 'entrega', 'movimiento'] }, construir: dialogoHistorial, textos: [] },
];

async function construirComponentes() {
  let y = 0;
  for (const def of DEFINICIONES) {
    const comps = [];
    for (const c of combinaciones(def.props)) {
      const comp = await def.construir(c);
      comp.name = nombreVariante(c);
      comps.push(comp);
    }
    disponer(comps, def.columnas || 4);
    const conjunto = figma.combineAsVariants(comps, figma.currentPage);
    conjunto.name = def.nombre;
    conjunto.fills = [pintura('ColorScheme/surface')];
    conjunto.strokes = [pintura('ColorScheme/outlineVariant')];
    conjunto.strokeWeight = 1;
    for (const t of def.textos) {
      const clave = conjunto.addComponentProperty(t[1], 'TEXT', t[2]);
      conjunto.findAll(n => n.type === 'TEXT' && n.name === t[0] && esPropio(n, conjunto)).forEach(n => {
        n.componentPropertyReferences = { characters: clave };
      });
    }
    const rotulo = await texto(def.nombre, 'subtitulo', 'ColorScheme/onSurface', 'rotulo');
    rotulo.x = 0;
    rotulo.y = y;
    conjunto.x = 0;
    conjunto.y = y + 40;
    y += 40 + conjunto.height + 80;
    conjuntos[def.nombre] = conjunto;
  }
}

async function seccion(raiz, titulo) {
  const s = marco({ nombre: titulo, dir: 'V', gap: 'e16' });
  s.appendChild(await texto(titulo, 'subtitulo', 'ColorScheme/onSurface', 'titulo'));
  raiz.appendChild(s);
  return s;
}

async function muestraColor(ruta) {
  const m = marco({ nombre: ruta, dir: 'V', gap: 'e4', ancho: 112 });
  const r = figma.createRectangle();
  r.name = 'color';
  r.resize(112, 56);
  r.fills = [pintura(ruta)];
  r.strokes = [pintura('ColorScheme/outlineVariant')];
  r.strokeWeight = 1;
  radio(r, 'r8');
  m.appendChild(r);
  agregar(m, await texto(ruta.split('/')[1], 'etiqueta', 'ColorScheme/onSurface', 'nombre'), { ancho: true });
  agregar(m, await texto(valorHex(ruta), 'ayuda', 'ColorScheme/onSurfaceVariant', 'hex'), { ancho: true });
  return m;
}

async function construirFundamentos() {
  const raiz = marco({ nombre: 'Fundamentos', dir: 'V', pad: 'e40', gap: 'e40', fondo: 'ColorScheme/surface' });
  figma.currentPage.appendChild(raiz);
  raiz.appendChild(await texto('TruequeU · Sistema de diseño', 'titulo', 'ColorScheme/onSurface', 'titulo'));

  const logos = await seccion(raiz, 'Logo');
  const filaLogos = marco({ nombre: 'logos', dir: 'H', gap: 'e32', cruz: 'CENTER' });
  filaLogos.appendChild(instancia('LogoTruequeU', { Variante: 'icono' }));
  filaLogos.appendChild(instancia('LogoTruequeU', { Variante: 'conNombre' }));
  logos.appendChild(filaLogos);

  for (const coleccion of ['TemaTruequeU', 'ColorScheme']) {
    const s = await seccion(raiz, 'Paleta · ' + coleccion);
    const claves = Object.keys(TOKENS[coleccion]);
    for (let i = 0; i < claves.length; i += 6) {
      const fila = marco({ nombre: 'fila', dir: 'H', gap: 'e12' });
      for (const clave of claves.slice(i, i + 6)) fila.appendChild(await muestraColor(coleccion + '/' + clave));
      s.appendChild(fila);
    }
  }

  const tipografia = await seccion(raiz, 'Tipografía · TextosTruequeU');
  for (const campo of Object.keys(TOKENS.TextosTruequeU)) {
    const def = TOKENS.TextosTruequeU[campo];
    const detalle = campo + ' · ' + numero(def.fontSize) + ' px · ' + PESOS[def.fontWeight];
    tipografia.appendChild(await texto(detalle, campo, 'ColorScheme/onSurface', 'muestra'));
  }

  const espacios = await seccion(raiz, 'Espacios');
  for (const campo of Object.keys(TOKENS.Espacios)) {
    const fila = marco({ nombre: campo, dir: 'H', gap: 'e12', cruz: 'CENTER' });
    const barra = figma.createRectangle();
    barra.name = 'barra';
    barra.resize(TOKENS.Espacios[campo], 16);
    barra.fills = [pintura('ColorScheme/primary')];
    ligar(barra, 'width', 'Espacios/' + campo);
    ligar(barra, 'height', 'Espacios/e16');
    fila.appendChild(barra);
    fila.appendChild(await texto(campo + ' · ' + TOKENS.Espacios[campo], 'detalle', 'ColorScheme/onSurface', 'valor'));
    espacios.appendChild(fila);
  }

  const radios = await seccion(raiz, 'Radios');
  const filaRadios = marco({ nombre: 'radios', dir: 'H', gap: 'e16', cruz: 'MIN' });
  for (const campo of Object.keys(TOKENS.Radios)) {
    const m = marco({ nombre: campo, dir: 'V', gap: 'e8', cruz: 'CENTER' });
    const caja = figma.createRectangle();
    caja.name = 'caja';
    caja.resize(72, 72);
    caja.fills = [pintura('ColorScheme/primaryContainer')];
    caja.strokes = [pintura('ColorScheme/primary')];
    caja.strokeWeight = 1;
    radio(caja, campo);
    m.appendChild(caja);
    m.appendChild(await texto(campo + ' · ' + TOKENS.Radios[campo], 'detalle', 'ColorScheme/onSurface', 'valor'));
    filaRadios.appendChild(m);
  }
  radios.appendChild(filaRadios);
}

function pantalla(nombre, indice) {
  const f = marco({ nombre: nombre, dir: 'V', ancho: 390, alto: 844, fondo: 'ColorScheme/surface', recorta: true });
  f.x = indice * 430;
  return f;
}

function contenido(padre, pad, gap) {
  const c = marco({ nombre: 'contenido', dir: 'V', pad: pad, gap: gap, recorta: true });
  agregar(padre, c, { ancho: true, alto: true });
  return c;
}

function encabezado(padre, conLogo, titulo, subtitulo) {
  const inst = instancia('EncabezadoAcceso', { ConLogo: conLogo ? 'si' : 'no' });
  cambiarTexto(inst, titulo, 'titulo');
  cambiarTexto(inst, subtitulo, 'subtitulo');
  agregar(padre, inst, { ancho: true });
}

function campo(padre, contenidoCampo, tipo) {
  const inst = instancia('CampoTexto', { Estado: 'vacio', Tipo: tipo || 'texto', Icono: 'no' });
  agregar(padre, cambiarTexto(inst, contenidoCampo), { ancho: true });
}

function accion(padre, contenidoBoton, variante) {
  agregar(padre, boton(contenidoBoton, variante), { ancho: true });
}

function navegacion(padre, activo) {
  agregar(padre, instancia('EstructuraPrincipal', { Activo: activo }), { ancho: true });
}

async function construirPantallas() {
  const inicio = pantalla('PantallaInicio', 0);
  encabezado(inicio, true, 'TruequeU', 'Intercambia lo que ya no usas');
  const accionesInicio = contenido(inicio, 'e24', 'e12');
  accion(accionesInicio, 'Iniciar sesión', 'primario');
  accion(accionesInicio, 'Crear cuenta', 'contorno');

  const acceso = pantalla('PantallaIniciarSesion', 1);
  encabezado(acceso, false, 'Iniciar sesión', 'Ingresa con tu correo institucional');
  const formularioAcceso = contenido(acceso, 'e24', 'e16');
  campo(formularioAcceso, 'Correo institucional');
  campo(formularioAcceso, 'Contraseña', 'contrasena');
  agregar(formularioAcceso, instancia('BannerError', { Estado: 'default' }), { ancho: true });
  accion(formularioAcceso, 'Entrar', 'primario');

  const registro = pantalla('PantallaRegistro', 2);
  encabezado(registro, false, 'Crear cuenta', 'Regístrate para intercambiar');
  const formularioRegistro = contenido(registro, 'e24', 'e16');
  campo(formularioRegistro, 'Nombre completo');
  campo(formularioRegistro, 'Correo institucional');
  campo(formularioRegistro, 'Contraseña', 'contrasena');
  campo(formularioRegistro, 'Confirmar contraseña', 'contrasena');
  accion(formularioRegistro, 'Registrarme', 'primario');

  const feed = pantalla('PantallaFeedPublicaciones', 3);
  const listaFeed = contenido(feed, 'e16', 'e12');
  agregar(listaFeed, instancia('FiltrosFeed', { Estado: 'conFiltros' }), { ancho: true });
  agregar(listaFeed, instancia('TarjetaFeed', { Estado: 'disponible' }), { ancho: true });
  agregar(listaFeed, instancia('TarjetaFeed', { Estado: 'reservadoPorOtro' }), { ancho: true });
  navegacion(feed, 'explorar');

  const mias = pantalla('PantallaMisPublicaciones', 4);
  const listaMias = contenido(mias, 'e16', 'e12');
  agregar(listaMias, instancia('TarjetaMiPublicacion', { Reservada: 'no' }), { ancho: true });
  agregar(listaMias, instancia('TarjetaMiPublicacion', { Reservada: 'si' }), { ancho: true });
  navegacion(mias, 'misPublicaciones');

  const perfil = pantalla('PantallaPerfil', 5);
  encabezado(perfil, false, 'Perfil', 'ana@universidad.edu');
  const datosPerfil = contenido(perfil, 'e24', 'e12');
  datosPerfil.appendChild(instancia('Estrellas', { Puntaje: '4', Modo: 'lectura' }));
  const etiquetas = marco({ nombre: 'etiquetas', dir: 'H', gap: 'e8' });
  etiquetas.appendChild(cambiarTexto(instancia('Etiqueta', { Tono: 'primario' }), '12 intercambios'));
  etiquetas.appendChild(cambiarTexto(instancia('Etiqueta', { Tono: 'terciario' }), 'Cuenta verificada'));
  datosPerfil.appendChild(etiquetas);
  accion(datosPerfil, 'Mis datos', 'contorno');
  accion(datosPerfil, 'Cambiar contraseña', 'contorno');
  accion(datosPerfil, 'Cerrar sesión', 'rojo');
  navegacion(perfil, 'perfil');
}

async function pagina(nombre) {
  let p = figma.root.children.find(x => x.name === nombre);
  if (!p) {
    p = figma.createPage();
    p.name = nombre;
  }
  await p.loadAsync();
  for (const hijo of p.children.slice()) hijo.remove();
  return p;
}

async function main() {
  await cargarFuentes();
  await prepararVariables();
  await prepararEstilos();
  const fundamentos = await pagina('🎨 Fundamentos');
  const componentes = await pagina('🧩 Componentes');
  const pantallas = await pagina('📱 Pantallas');
  await figma.setCurrentPageAsync(componentes);
  await construirComponentes();
  await figma.setCurrentPageAsync(fundamentos);
  await construirFundamentos();
  await figma.setCurrentPageAsync(pantallas);
  await construirPantallas();
  await figma.setCurrentPageAsync(fundamentos);
}

main()
  .then(() => figma.closePlugin('Sistema de diseño TruequeU generado'))
  .catch(error => figma.closePlugin('Error: ' + (error && error.message ? error.message : error)));
