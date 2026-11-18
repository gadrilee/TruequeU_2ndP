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
  };
  const par = pares[c.Variante];
  const contorno = c.Variante === 'contorno';
  const apagado = c.Estado === 'deshabilitado' || c.Estado === 'cargando';
  const opacidades = { default: 1, hover: 0.92, presionado: 0.84 };
  let fondo = par[0];
  let opacidad = opacidades[c.Estado];
  let color = par[1];
  let opacidadTexto;
  let borde = contorno ? 'ColorScheme/outlineVariant' : null;
  let opacidadBorde;
  if (contorno && (c.Estado === 'hover' || c.Estado === 'presionado')) {
    fondo = 'ColorScheme/primary';
    opacidad = c.Estado === 'hover' ? 0.08 : 0.12;
  }
  if (apagado) {
    fondo = contorno ? null : 'ColorScheme/onSurface';
    opacidad = 0.12;
    color = 'ColorScheme/onSurface';
    opacidadTexto = 0.38;
    if (contorno) {
      borde = 'ColorScheme/onSurface';
      opacidadBorde = 0.12;
    }
  }
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 280, alto: contorno ? 48 : 52, pad: [null, 'e16'],
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
  const caja = marco({
    nombre: 'campo', dir: 'H', alto: 56, pad: [null, 'e16'], gap: 'e12', radio: 'r14',
    fondo: apagado ? 'ColorScheme/surfaceContainerHighest' : 'TemaTruequeU/blanco',
    borde: error ? 'ColorScheme/error' : enfocado ? 'ColorScheme/primary' : 'ColorScheme/outlineVariant',
    grosor: error || enfocado ? 2 : 1, cruz: 'CENTER',
  });
  agregar(raiz, caja, { ancho: true });
  const vacio = c.Estado === 'vacio';
  let contenido = vacio ? 'Correo institucional' : 'ana@universidad.edu';
  if (c.Tipo === 'contrasena') contenido = vacio ? 'Contraseña' : '••••••••';
  const t = await texto(contenido, 'cuerpo', vacio ? 'ColorScheme/onSurfaceVariant' : 'ColorScheme/onSurface', 'texto', apagado ? 0.38 : undefined);
  agregar(caja, t, { ancho: true });
  if (c.Tipo === 'contrasena') caja.appendChild(await glifo('◉', 'ColorScheme/outline', 'cuerpo'));
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

const DEFINICIONES = [
  { nombre: 'LogoTruequeU', props: { Variante: ['icono', 'conNombre'] }, construir: logo, textos: [] },
  {
    nombre: 'BotonCarga',
    props: { Estado: ['default', 'hover', 'presionado', 'cargando', 'deshabilitado'], Variante: ['primario', 'rojo', 'tonal', 'contorno'] },
    construir: botonCarga, textos: [['texto', 'texto', 'Continuar']], columnas: 5,
  },
  {
    nombre: 'CampoTexto',
    props: { Estado: ['vacio', 'enfocado', 'relleno', 'error', 'deshabilitado'], Tipo: ['texto', 'contrasena'] },
    construir: campoTexto, textos: [['texto', 'texto', 'Correo institucional']], columnas: 5,
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

async function construirPantallas() {
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
