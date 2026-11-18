const FUENTE = 'Roboto';
const PESOS = { 400: 'Regular', 500: 'Medium', 600: 'SemiBold', 700: 'Bold' };
const COLECCIONES_TEXTO = ['TextTheme', 'TextosTruequeU', 'TextoDerivado'];
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

function definicionTexto(ruta) {
  const partes = ruta.split('/');
  const def = COLECCIONES_TEXTO.indexOf(partes[0]) === -1 ? undefined : TOKENS[partes[0]][partes[1]];
  if (!def) throw new Error('Estilo inexistente: ' + ruta);
  return def;
}

function tamanoTexto(def) {
  return typeof def.fontSize === 'string' ? numero(def.fontSize) : def.fontSize;
}

function variableTamano(def) {
  if (typeof def.fontSize === 'string') return variable(def.fontSize);
  return vars['Tipos/t' + def.fontSize] || null;
}

function alturaLinea(def) {
  if (def.height === null) return { unit: 'AUTO' };
  return { unit: 'PIXELS', value: Math.round(tamanoTexto(def) * def.height * 100) / 100 };
}

async function prepararEstilos() {
  const existentes = await figma.getLocalTextStylesAsync();
  for (const coleccion of COLECCIONES_TEXTO) {
    for (const campo of Object.keys(TOKENS[coleccion])) {
      const def = TOKENS[coleccion][campo];
      const nombre = coleccion + '/' + campo;
      let estilo = existentes.find(s => s.name === nombre);
      if (!estilo) estilo = figma.createTextStyle();
      estilo.name = nombre;
      estilo.fontName = { family: FUENTE, style: PESOS[def.fontWeight] };
      estilo.fontSize = tamanoTexto(def);
      const enlace = variableTamano(def);
      if (enlace) estilo.setBoundVariable('fontSize', enlace);
      estilo.lineHeight = alturaLinea(def);
      estilo.letterSpacing = { unit: 'PIXELS', value: def.letterSpacing || 0 };
      estilo.description = coleccion + '.' + campo;
      estilos[nombre] = estilo;
    }
  }
}

async function cargarFuentes() {
  for (const peso of Object.keys(PESOS)) {
    try {
      await figma.loadFontAsync({ family: FUENTE, style: PESOS[peso] });
    } catch (error) {
      if (peso !== '600') throw error;
      PESOS[600] = 'Bold';
    }
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

function rutaEstilo(estilo) {
  return estilo.indexOf('/') === -1 ? 'TextosTruequeU/' + estilo : estilo;
}

async function texto(contenido, estilo, color, nombre, opacidad) {
  const t = figma.createText();
  const ruta = rutaEstilo(estilo);
  const def = definicionTexto(ruta);
  t.fontName = { family: FUENTE, style: PESOS[def.fontWeight] };
  t.characters = contenido;
  t.name = nombre || 'texto';
  await t.setTextStyleIdAsync(estilos[ruta].id);
  t.fills = [pintura(color, opacidad)];
  return t;
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

function pintarIcono(inst, color, opacidad) {
  inst.findOne(n => n.type === 'VECTOR').fills = [pintura(color, opacidad)];
}

function icono(nombre, color, tam, opacidad, conjunto) {
  const inst = instancia(conjunto || 'Icono', { nombre: nombre });
  inst.name = 'icono';
  if (tam && tam !== 24) inst.resize(tam, tam);
  pintarIcono(inst, color, opacidad);
  return inst;
}

function cambiarIcono(inst, nombre, tam) {
  const interno = inst.findOne(n => n.type === 'INSTANCE' && n.name === 'icono');
  if (!interno) throw new Error('La instancia no tiene icono');
  const anterior = interno.findOne(n => n.type === 'VECTOR').fills;
  interno.setProperties({ nombre: nombre });
  interno.findOne(n => n.type === 'VECTOR').fills = anterior;
  if (tam) interno.resize(tam, tam);
  return inst;
}

function iconoBase(fuente) {
  return async function (c) {
    const raiz = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 24, alto: 24 });
    const svg = figma.createNodeFromSvg(fuente[c.nombre]);
    const vector = figma.flatten(svg.children, svg);
    const x = vector.x;
    const y = vector.y;
    raiz.appendChild(vector);
    vector.layoutPositioning = 'ABSOLUTE';
    vector.x = x;
    vector.y = y;
    vector.constraints = { horizontal: 'SCALE', vertical: 'SCALE' };
    vector.name = 'glifo';
    vector.fills = [pintura('ColorScheme/onSurfaceVariant')];
    svg.remove();
    return raiz;
  };
}

function disponer(comps, columnas) {
  const ancho = Math.max.apply(null, comps.map(c => c.width)) + 24;
  const alto = Math.max.apply(null, comps.map(c => c.height)) + 24;
  comps.forEach((c, i) => {
    c.x = (i % columnas) * ancho;
    c.y = Math.floor(i / columnas) * alto;
  });
}

async function mini(contenido, fondo, color, estilo) {
  const f = marco({ nombre: 'mini', dir: 'H', pad: ['e4', 'e8'], radio: 'r8', fondo: fondo, cruz: 'CENTER' });
  f.appendChild(await texto(contenido, estilo || 'chip', color, 'texto'));
  return f;
}

async function logo(c) {
  const conNombre = c.Variante === 'conNombre';
  const caja = marco({
    nombre: conNombre ? 'caja' : 'raiz', componente: !conNombre, dir: 'H', ancho: 64, alto: 64, radio: 'r20',
    fondo: 'TemaTruequeU/blanco', alinea: 'CENTER', cruz: 'CENTER',
  });
  caja.appendChild(icono('swap_horiz', 'TemaTruequeU/rojo', 36));
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
    gap: c.Icono === 'si' ? 'e8' : null, radio: 'r28', fondo: fondo, opacidad: opacidad, borde: borde, opacidadBorde: opacidadBorde,
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
    if (c.Icono === 'si') f.appendChild(icono('add', color, 18, opacidadTexto));
    f.appendChild(await texto('Continuar', 'TextTheme/labelLarge', color, 'texto', opacidadTexto));
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
  const colorIcono = apagado ? 'ColorScheme/onSurface' : 'ColorScheme/onSurfaceVariant';
  if (c.Icono === 'si') caja.appendChild(icono('mail_outline', colorIcono, 24, apagado ? 0.38 : undefined));
  const t = await texto(
    contenido,
    vacio ? 'TextoDerivado/campoEtiqueta' : 'TextTheme/bodyLarge',
    vacio ? 'ColorScheme/onSurfaceVariant' : 'ColorScheme/onSurface',
    'texto',
    apagado ? 0.38 : undefined,
  );
  agregar(caja, t, { ancho: true });
  if (c.Tipo === 'contrasena') {
    const colorVer = error ? 'ColorScheme/error' : colorIcono;
    const ver = icono('visibility_outlined', colorVer, 24, apagado ? 0.38 : undefined);
    ver.name = 'ver';
    caja.appendChild(ver);
  }
  if (error) agregar(raiz, await texto('Revisa este campo', 'TextTheme/bodySmall', 'ColorScheme/error', 'ayuda'), { ancho: true });
  return raiz;
}

async function bannerError() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 320, pad: 'e12', radio: 'r8', fondo: 'ColorScheme/errorContainer' });
  agregar(f, await texto('No pudimos conectar con el servidor', 'TextTheme/bodyMedium', 'ColorScheme/onErrorContainer', 'mensaje'), { ancho: true });
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

const ICONOS_ETIQUETA = { primario: 'label_outline', secundario: 'person_pin_outlined', terciario: 'chat_outlined' };

async function etiqueta(c) {
  const d = TONOS[c.Tono];
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', pad: ['e4', 'e10'], gap: 'e4', radio: 'r16', fondo: d[0], cruz: 'CENTER' });
  f.appendChild(icono(ICONOS_ETIQUETA[c.Tono], d[1], 14));
  f.appendChild(await texto('Libros', 'etiqueta', d[1], 'texto'));
  return f;
}

async function estrellas(c) {
  const interactivo = c.Modo === 'interactivo';
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', pad: interactivo ? null : 'e4', gap: interactivo ? 'e2' : null, cruz: 'CENTER' });
  for (let i = 1; i <= 5; i++) {
    const g = icono(i <= Number(c.Puntaje) ? 'star' : 'star_border', 'ColorScheme/secondary', 24);
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
  if (c.Estado === 'vacia') f.appendChild(icono('image_outlined', 'ColorScheme/outline', 24));
  if (c.Estado === 'imagen') f.appendChild(await texto('Foto', 'TextTheme/bodyMedium', 'ColorScheme/onPrimaryContainer', 'foto'));
  if (c.Estado === 'error') f.appendChild(icono('broken_image_outlined', 'ColorScheme/onSurface', 24));
  return f;
}

async function mensajeVacio(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'V', ancho: 320, pad: 'e32', gap: 'e16', cruz: 'CENTER' });
  f.appendChild(icono('feed_outlined', 'ColorScheme/outline', 64));
  const titulo = await texto('Aún no hay publicaciones', 'subtitulo', 'ColorScheme/onSurface', 'titulo');
  titulo.textAlignHorizontal = 'CENTER';
  agregar(f, titulo, { ancho: true });
  const mensaje = await texto('Publica un objeto para empezar a intercambiar', 'TextTheme/bodyMedium', 'ColorScheme/onSurface', 'mensaje');
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
  buscador.appendChild(icono('search', 'ColorScheme/onSurfaceVariant', 24));
  agregar(buscador, await texto('Buscar objetos', 'TextTheme/bodyLarge', 'ColorScheme/onSurfaceVariant', 'busqueda'), { ancho: true });
  buscador.appendChild(icono('arrow_forward', 'ColorScheme/onSurfaceVariant', 24));
  agregar(f, buscador, { ancho: true });

  const menus = marco({ nombre: 'menus', dir: 'H', gap: 'e8' });
  for (const nombre of ['Categoría', 'Condición', 'Disponibilidad']) {
    const chip = marco({
      nombre: nombre, dir: 'H', pad: ['e4', 'e12'], gap: 'e4', radio: 'r28',
      fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
    });
    chip.appendChild(icono('tune', 'ColorScheme/primary', 16));
    chip.appendChild(await texto(nombre, 'TextTheme/labelLarge', 'ColorScheme/onSurfaceVariant', 'texto'));
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
      chip.appendChild(await texto(contenido, 'TextTheme/labelLarge', 'ColorScheme/onSurfaceVariant', 'texto'));
      chip.appendChild(icono('close', 'ColorScheme/onSurfaceVariant', 18));
      activos.appendChild(chip);
    }
    activos.appendChild(await texto('Quitar todos', 'TextTheme/labelLarge', 'ColorScheme/primary', 'quitar'));
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

function boton(contenido, variante, estado, nombreIcono, tam) {
  const inst = cambiarTexto(instancia('BotonCarga', { Estado: estado || 'default', Variante: variante, Icono: nombreIcono ? 'si' : 'no' }), contenido);
  if (nombreIcono) cambiarIcono(inst, nombreIcono, tam || 18);
  return inst;
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
  autor.appendChild(icono('person_outline', 'ColorScheme/outline', 14));
  autor.appendChild(await texto(d.autor, d.propia ? 'TextoDerivado/autorPropio' : 'ayuda', d.propia ? 'ColorScheme/primary' : 'ColorScheme/outline', 'autor'));
  agregar(f, autor);

  agregar(f, await texto('Casi nueva, incluye funda y manual.', 'detalle', 'ColorScheme/onSurfaceVariant', 'descripcion'), { ancho: true });

  const datos = marco({ nombre: 'datos', dir: 'H', gap: 'e6', cruz: 'CENTER' });
  datos.appendChild(await mini('Condición: Usado', 'ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer'));
  datos.appendChild(await mini('Categoría: Electrónica', 'ColorScheme/primaryContainer', 'ColorScheme/onPrimaryContainer'));
  if (d.reserva) datos.appendChild(await mini(d.reserva, 'ColorScheme/secondaryContainer', 'ColorScheme/onSecondaryContainer', 'TextoDerivado/chipSemibold'));
  agregar(f, datos);

  const acciones = marco({ nombre: 'acciones', dir: 'V', gap: 'e6' });
  agregar(f, acciones, { ancho: true });
  if (c.Estado === 'disponible') {
    agregar(acciones, boton('Ofrecer un objeto', 'primario', 'default', 'swap_horiz'), { ancho: true });
    agregar(acciones, boton('Reservar', 'contorno', 'default', 'bookmark_add_outlined'), { ancho: true });
    agregar(acciones, await texto('Ofrecer: cambias un objeto tuyo. Reservar: solo lo apartas.', 'pie', 'ColorScheme/outline', 'pie'), { ancho: true });
  }
  if (c.Estado === 'reservadoPorMi') {
    agregar(acciones, boton('Completar intercambio', 'primario', 'default', 'handshake_outlined'), { ancho: true });
    const fila = marco({ nombre: 'fila', dir: 'H', gap: 'e8' });
    agregar(acciones, fila, { ancho: true });
    agregar(fila, boton('WhatsApp', 'contorno', 'default', 'chat_outlined'), { ancho: true });
    agregar(fila, boton('Cancelar reserva', 'contorno', 'default', 'close'), { ancho: true });
  }
  if (c.Estado === 'reservadoPorOtro') agregar(acciones, boton('Reservado', 'tonal', 'deshabilitado'), { ancho: true });
  if (c.Estado === 'propia') agregar(acciones, boton('Ver en mis publicaciones', 'contorno', 'default', 'edit_outlined', 16), { ancho: true });
  if (c.Estado === 'ofertaEnviada') {
    agregar(acciones, boton('Oferta enviada', 'tonal', 'deshabilitado'), { ancho: true });
    agregar(acciones, boton('Ver mis ofertas', 'contorno'), { ancho: true });
  }
  if (c.Estado === 'intercambiado') agregar(acciones, boton('Intercambio completado', 'tonal', 'deshabilitado'), { ancho: true });
  return f;
}

function botonIcono(nombreIcono, color) {
  const f = marco({ nombre: 'boton', dir: 'H', ancho: 40, alto: 40, alinea: 'CENTER', cruz: 'CENTER' });
  f.appendChild(icono(nombreIcono, color, 20));
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
  if (!reservada) {
    cabecera.appendChild(botonIcono('edit_outlined', 'ColorScheme/primary'));
    cabecera.appendChild(botonIcono('more_vert', 'ColorScheme/onSurfaceVariant'));
    cabecera.appendChild(botonIcono('delete_outline', 'ColorScheme/error'));
  }
  agregar(f, cabecera, { ancho: true });

  agregar(f, await texto('Casi nueva, incluye funda y manual.', 'cuerpo', 'ColorScheme/onSurfaceVariant', 'descripcion'), { ancho: true });

  const datos = marco({ nombre: 'datos', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  datos.appendChild(instancia('Etiqueta', { Tono: 'primario' }));
  datos.appendChild(instancia('ChipEstado', { Estado: reservada ? 'reservado' : 'disponible' }));
  agregar(f, datos);

  if (reservada) {
    agregar(f, await texto('Está reservada: solo puedes completar el intercambio.', 'ayuda', 'ColorScheme/onSurfaceVariant', 'reserva'), { ancho: true });
    agregar(f, boton('Completar intercambio', 'primario', 'default', 'handshake_outlined', 16), { ancho: true });
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
    f.appendChild(icono('arrow_back', 'TemaTruequeU/blanco', 24));
  }
  const titulo = await texto('Iniciar sesión', 'TextoDerivado/headlineMediumNegrita', 'ColorScheme/onPrimary', 'titulo');
  const subtitulo = await texto('Bienvenido de vuelta', 'TextTheme/bodyLarge', 'ColorScheme/primaryContainer', 'subtitulo');
  if (conLogo) {
    titulo.textAlignHorizontal = 'CENTER';
    subtitulo.textAlignHorizontal = 'CENTER';
  }
  agregar(f, titulo, { ancho: true });
  agregar(f, subtitulo, { ancho: true });
  return f;
}

const DESTINOS = [
  ['explorar', 'explore_outlined', 'explore', 'Explorar'],
  ['misPublicaciones', 'inventory_2_outlined', 'inventory_2', 'Mis publicaciones'],
  ['ofertas', 'swap_horiz', 'swap_horiz', 'Ofertas'],
  ['perfil', 'person_outline', 'person', 'Perfil'],
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
    pastilla.appendChild(icono(activo ? d[2] : d[1], activo ? 'ColorScheme/onSecondaryContainer' : 'ColorScheme/onSurfaceVariant', 24));
    destino.appendChild(pastilla);
    destino.appendChild(await texto(d[3], 'TextTheme/labelMedium', activo ? 'ColorScheme/onSurface' : 'ColorScheme/onSurfaceVariant', 'texto'));
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
  subtitulo: ['TextoDerivado/headlineSmallNegrita', 'ColorScheme/onSurface'],
  cuerpo: ['TextTheme/bodyMedium', 'ColorScheme/onSurface'],
  negrita: ['TextoDerivado/bodyMediumNegrita', 'ColorScheme/onSurface'],
  suave: ['TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant'],
  ayuda: ['TextTheme/bodySmall', 'ColorScheme/onSurfaceVariant'],
  error: ['TextTheme/bodyMedium', 'ColorScheme/error'],
  enlace: ['TextTheme/labelLarge', 'ColorScheme/primary'],
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
  if (c.Volver === 'si') f.appendChild(icono('arrow_back', 'TemaTruequeU/azulOscuro', 24));
  agregar(f, await texto('Título de la pantalla', 'TextTheme/titleLarge', 'TemaTruequeU/azulOscuro', 'titulo'), { ancho: true });
  if (c.Accion === 'refrescar') f.appendChild(icono('refresh', 'TemaTruequeU/azulOscuro', 24));
  return f;
}

async function botonFlotante() {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', alto: 56, pad: [null, 'e20'], gap: 'e8', radio: 'r28',
    fondo: 'ColorScheme/secondary', alinea: 'CENTER', cruz: 'CENTER',
  });
  f.appendChild(icono('add', 'ColorScheme/onSecondary', 24));
  f.appendChild(await texto('Publicar', 'TextTheme/labelLarge', 'ColorScheme/onSecondary', 'texto'));
  return f;
}

async function snackBar() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, pad: 'e16', fondo: 'ColorScheme/onSurface', cruz: 'CENTER' });
  agregar(f, await texto('Contraseña actualizada.', 'TextTheme/bodyMedium', 'ColorScheme/surface', 'texto'), { ancho: true });
  return f;
}

async function circleAvatar(c) {
  const grande = c.Tamano === 'grande';
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: grande ? 72 : 22, alto: grande ? 72 : 22, radio: grande ? 'r36' : 'r12',
    fondo: grande ? 'ColorScheme/primary' : 'ColorScheme/primaryContainer', alinea: 'CENTER', cruz: 'CENTER',
  });
  if (grande) f.appendChild(await texto('AP', 'TextoDerivado/avatarGrande', 'ColorScheme/onPrimary', 'texto'));
  else f.appendChild(await texto('1', 'TextoDerivado/avatarChico', 'ColorScheme/onPrimaryContainer', 'texto'));
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
  agregar(textos, await texto('Estado del objeto', 'TextoDerivado/campoEtiquetaFlotante', 'ColorScheme/onSurfaceVariant', 'etiqueta'), { ancho: true });
  agregar(textos, await texto('Nuevo', 'TextTheme/titleMedium', 'ColorScheme/onSurface', 'valor'), { ancho: true });
  agregar(f, textos, { ancho: true });
  f.appendChild(icono('arrow_drop_down', 'ColorScheme/onSurfaceVariant', 24, undefined, 'IconoMarco'));
  return f;
}

async function iconoCaja() {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 56, alto: 56, radio: 'r16',
    fondo: 'ColorScheme/primaryContainer', alinea: 'CENTER', cruz: 'CENTER',
  });
  f.appendChild(icono('vpn_key', 'ColorScheme/primary', 24));
  return f;
}

async function bannerExito() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: 'e16', gap: 'e12', radio: 'r14', fondo: 'ColorScheme/tertiaryContainer', cruz: 'CENTER' });
  f.appendChild(icono('check_circle_outline', 'ColorScheme/onTertiaryContainer', 24));
  agregar(f, await texto('Listo. Revisa tu correo: ahí está tu contraseña nueva.', 'TextTheme/bodyMedium', 'ColorScheme/onTertiaryContainer', 'mensaje'), { ancho: true });
  return f;
}

async function pieEnlace(c) {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, pad: [null, null, 'e16', null], gap: 'e4', alinea: 'CENTER', cruz: 'CENTER' });
  const crear = c.Variante === 'crearCuenta';
  f.appendChild(await texto(crear ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?', 'TextTheme/bodyMedium', 'ColorScheme/onSurface', 'pregunta'));
  f.appendChild(await texto(crear ? 'Crear cuenta' : 'Inicia sesión', 'TextoDerivado/botonTextoNegrita', crear ? 'ColorScheme/secondary' : 'ColorScheme/primary', 'enlace'));
  return f;
}

async function cabeceraFeed() {
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 390, pad: ['e16', 'e8', null, 'e20'], gap: 'e8', cruz: 'CENTER' });
  const columna = marco({ nombre: 'saludo', dir: 'V', gap: 'e2' });
  agregar(columna, await texto('Hola, Ana', 'TextTheme/bodyLarge', 'ColorScheme/onSurface', 'saludo'), { ancho: true });
  agregar(columna, await texto('¿Qué quieres intercambiar hoy?', 'TextoDerivado/titleLargeNegrita', 'ColorScheme/onSurface', 'pregunta'), { ancho: true });
  agregar(f, columna, { ancho: true });
  for (const g of ['help_outline', 'refresh']) {
    const b = marco({ nombre: 'boton', dir: 'H', ancho: 40, alto: 40, alinea: 'CENTER', cruz: 'CENTER' });
    b.appendChild(icono(g, 'ColorScheme/onSurfaceVariant', 24));
    f.appendChild(b);
  }
  return f;
}

async function segmentado(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, alto: 40, radio: 'r28', fondo: 'TemaTruequeU/blanco',
    borde: 'ColorScheme/outline', recorta: true,
  });
  const segmentos = [['recibidas', 'inbox_outlined', 'Recibidas'], ['enviadas', 'outbox_outlined', 'Enviadas']];
  for (const s of segmentos) {
    const activo = s[0] === c.Seleccionado;
    const color = activo ? 'ColorScheme/onSecondaryContainer' : 'ColorScheme/onSurface';
    const seg = marco({
      nombre: 'segmento-' + s[0], dir: 'H', gap: 'e8', fondo: activo ? 'ColorScheme/secondaryContainer' : null,
      alinea: 'CENTER', cruz: 'CENTER',
    });
    seg.appendChild(activo ? icono('check', color, 18, undefined, 'IconoMarco') : icono(s[1], color, 18));
    seg.appendChild(await texto(s[2], 'TextTheme/labelLarge', color, s[0]));
    agregar(f, seg, { ancho: true, alto: true });
  }
  return f;
}

async function filaLista(c) {
  const error = c.Tono === 'error';
  const f = marco({ nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: ['e8', 'e16'], gap: 'e16', cruz: 'CENTER' });
  if (c.Icono === 'con') f.appendChild(icono('handshake_outlined', error ? 'ColorScheme/error' : 'ColorScheme/primary', 24));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(columna, await texto('Intercambios completados', 'TextTheme/bodyLarge', error ? 'ColorScheme/error' : 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  if (c.Subtitulo === 'con') agregar(columna, await texto('Subtítulo', 'TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant', 'subtitulo'), { ancho: true });
  agregar(f, columna, { ancho: true });
  if (c.Final === 'chevron') f.appendChild(icono('chevron_right', 'ColorScheme/onSurfaceVariant', 24));
  return f;
}

async function resumenCalificaciones(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, alto: c.Estado === 'cargando' ? 24 : null, gap: 'e6',
    alinea: 'CENTER', cruz: 'CENTER',
  });
  if (c.Estado === 'vacio') {
    const t = await texto('Aún no tienes calificaciones', 'TextTheme/bodyMedium', 'ColorScheme/onSurface', 'texto');
    t.textAlignHorizontal = 'CENTER';
    agregar(f, t, { ancho: true });
  }
  if (c.Estado === 'conDatos') {
    f.appendChild(icono('star_border', 'ColorScheme/secondary', 24));
    f.appendChild(await texto('4.5 de 5 · 12 calificaciones', 'TextTheme/bodyMedium', 'ColorScheme/onSurface', 'texto'));
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

async function chipMaterial(contenido, nombreIcono) {
  const f = marco({ nombre: 'chip', dir: 'H', pad: ['e4', 'e8'], gap: 'e4', radio: 'r8', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER' });
  if (nombreIcono) f.appendChild(icono(nombreIcono, 'ColorScheme/primary', 16));
  f.appendChild(await texto(contenido, 'TextTheme/labelLarge', 'ColorScheme/onSurfaceVariant', 'texto'));
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
  agregar(f, await texto(entregue ? 'Lo entregaste a: Luis Gómez' : 'Lo recibiste de: Ana Pérez', 'TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant', 'quien'), { ancho: true });
  const chips = marco({ nombre: 'chips', dir: 'H', gap: 'e8' });
  chips.appendChild(await chipMaterial('Categoría: Electrónica'));
  chips.appendChild(await chipMaterial('Intercambiado', 'check_circle_outline'));
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
  f.appendChild(await texto(d[2], 'TextoDerivado/bodyMediumSemibold', d[1], 'texto'));
  return f;
}

async function tarjetaOferta(c) {
  const recibida = c.Lado === 'recibida';
  const f = tarjetaBase('e8');
  const cabecera = marco({ nombre: 'cabecera', dir: 'H', gap: 'e8', cruz: 'CENTER' });
  cabecera.appendChild(instancia('ChipEstadoOferta', { Estado: c.Estado }));
  const quien = await texto(recibida ? 'De: Luis Gómez' : 'Para: Ana Pérez', 'TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant', 'quien');
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
    chip.appendChild(await texto(d[1], 'TextTheme/labelLarge', activo ? 'ColorScheme/onSecondaryContainer' : 'ColorScheme/onSurfaceVariant', 'texto'));
    f.appendChild(chip);
  }
  return f;
}

const MOVIMIENTOS = {
  reservo: ['bookmark_outline', 'Reservaste «Calculadora científica» de Luis Gómez', 'Reservado · 20 oct'],
  canceloReserva: ['cancel_outlined', 'Luis Gómez canceló su reserva de «Calculadora científica»', 'Reserva cancelada · 18 oct'],
  completo: ['check_circle_outline', 'Completaste el intercambio de «Calculadora científica» con Luis Gómez', 'Completado · 15 oct'],
};

async function tarjetaHistorial(c) {
  const d = MOVIMIENTOS[c.Tipo];
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: 'e16', gap: 'e12', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
  });
  f.appendChild(icono(d[0], 'ColorScheme/onSurface', 28));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e4' });
  agregar(columna, await texto(d[1], 'tituloItem', 'ColorScheme/onSurface', 'frase'), { ancho: true });
  agregar(columna, await texto(d[2], 'TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant', 'estado'), { ancho: true });
  agregar(f, columna, { ancho: true });
  f.appendChild(icono('chevron_right', 'ColorScheme/onSurface', 24));
  return f;
}

async function tarjetaAviso(c) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'H', ancho: 350, pad: ['e8', 'e16'], gap: 'e16', radio: 'r20',
    fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', cruz: 'CENTER',
  });
  f.appendChild(icono(c.Estado === 'noLeida' ? 'notifications_active' : 'notifications_none', 'ColorScheme/primary', 24));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(columna, await texto('Luis Gómez aceptó tu oferta por «Calculadora científica»', 'TextTheme/bodyLarge', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  agregar(columna, await texto('12/11/2026', 'TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant', 'subtitulo'), { ancho: true });
  agregar(f, columna, { ancho: true });
  return f;
}

async function tarjetaDatos(c) {
  const f = tarjetaBase('e8');
  agregar(f, await texto('Tu perfil', 'TextoDerivado/titleMediumNegrita', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  agregar(f, await texto('Nombre: Ana Pérez\nCorreo: ana@universidad.edu', 'TextTheme/bodyMedium', 'ColorScheme/onSurface', 'lineas'), { ancho: true });
  if (c.Variante === 'conAccion') agregar(f, tp('Quitar mi teléfono', 'enlace'), { ancho: true });
  return f;
}

async function dialogoBase(titulo, alto) {
  const f = marco({
    nombre: 'raiz', componente: true, dir: 'V', ancho: 310, alto: alto, pad: 'e24', gap: 'e16', radio: 'r28',
    fondo: 'ColorScheme/surface', recorta: !!alto,
  });
  agregar(f, await texto(titulo, 'TextTheme/headlineSmall', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
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

function botonRadio(marcada) {
  const f = marco({ nombre: 'radio', dir: 'H', ancho: 20, alto: 20 });
  const color = marcada ? 'ColorScheme/primary' : 'ColorScheme/onSurfaceVariant';
  const anillo = figma.createEllipse();
  anillo.name = 'anillo';
  anillo.resize(16, 16);
  anillo.fills = [];
  anillo.strokes = [pintura(color)];
  anillo.strokeWeight = 2;
  f.appendChild(anillo);
  anillo.layoutPositioning = 'ABSOLUTE';
  anillo.x = 2;
  anillo.y = 2;
  if (marcada) {
    const punto = figma.createEllipse();
    punto.name = 'punto';
    punto.resize(9, 9);
    punto.fills = [pintura(color)];
    f.appendChild(punto);
    punto.layoutPositioning = 'ABSOLUTE';
    punto.x = 5.5;
    punto.y = 5.5;
  }
  return f;
}

async function filaRadio(titulo, subtitulo, marcada) {
  const f = marco({ nombre: 'opcion', dir: 'H', gap: 'e12', cruz: 'CENTER' });
  f.appendChild(botonRadio(marcada));
  const columna = marco({ nombre: 'textos', dir: 'V', gap: 'e2' });
  agregar(columna, await texto(titulo, 'TextTheme/bodyLarge', 'ColorScheme/onSurface', 'titulo'), { ancho: true });
  agregar(columna, await texto(subtitulo, 'TextTheme/bodyMedium', 'ColorScheme/onSurfaceVariant', 'subtitulo'), { ancho: true });
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
      ['Estado: Reservado', 'suave', 'bookmark_outline'], ['Categoría: Electrónica', 'suave'], ['Con: Luis Gómez', 'suave'],
      ['Fecha: 20 oct 2026, 16:24', 'suave'],
    ],
  };
  const cuerpo = marco({ nombre: 'contenido', dir: 'V', gap: 'e8' });
  agregar(f, cuerpo, { ancho: true });
  lineas[c.Tipo].forEach(l => {
    if (!l[2]) {
      agregar(cuerpo, tp(l[0], l[1]), { ancho: true });
      return;
    }
    const fila = marco({ nombre: 'fila', dir: 'H', gap: 'e8', cruz: 'CENTER' });
    fila.appendChild(icono(l[2], 'ColorScheme/onSurface', 18));
    agregar(fila, tp(l[0], l[1]), { ancho: true });
    agregar(cuerpo, fila, { ancho: true });
  });
  agregar(f, boton('Cerrar', 'primario'), { ancho: true });
  return f;
}

const DEFINICIONES = [
  { nombre: 'Icono', props: { nombre: Object.keys(ICONOS) }, construir: iconoBase(ICONOS), textos: [], columnas: 8 },
  { nombre: 'IconoMarco', props: { nombre: Object.keys(ICONOS_MARCO) }, construir: iconoBase(ICONOS_MARCO), textos: [] },
  { nombre: 'LogoTruequeU', props: { Variante: ['icono', 'conNombre'] }, construir: logo, textos: [] },
  {
    nombre: 'BotonCarga',
    props: {
      Estado: ['default', 'hover', 'presionado', 'cargando', 'deshabilitado'],
      Variante: ['primario', 'rojo', 'tonal', 'contorno', 'contornoRojo', 'texto'],
      Icono: ['no', 'si'],
    },
    construir: botonCarga, textos: [['texto', 'texto', 'Continuar']], columnas: 12,
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

  for (const coleccion of COLECCIONES_TEXTO) {
    const tipografia = await seccion(raiz, 'Tipografía · ' + coleccion);
    for (const campo of Object.keys(TOKENS[coleccion])) {
      const def = TOKENS[coleccion][campo];
      const lineaAlto = def.height === null ? 'auto' : alturaLinea(def).value + ' px';
      const detalle = campo + ' · ' + tamanoTexto(def) + ' px · ' + PESOS[def.fontWeight] + ' · altura ' + lineaAlto + ' · espaciado ' + (def.letterSpacing || 0);
      tipografia.appendChild(await texto(detalle, coleccion + '/' + campo, 'ColorScheme/onSurface', 'muestra'));
    }
  }

  const iconos = await seccion(raiz, 'Íconos · Material Icons');
  for (const [titulo, fuente, conjunto] of [['Íconos de la app', ICONOS, 'Icono'], ['Íconos internos de Material', ICONOS_MARCO, 'IconoMarco']]) {
    iconos.appendChild(await texto(titulo, 'TextTheme/bodySmall', 'ColorScheme/onSurfaceVariant', 'subtitulo'));
    const nombres = Object.keys(fuente);
    for (let i = 0; i < nombres.length; i += 8) {
      const fila = marco({ nombre: 'fila', dir: 'H', gap: 'e12' });
      for (const nombre of nombres.slice(i, i + 8)) {
        const celda = marco({ nombre: nombre, dir: 'V', gap: 'e4', ancho: 120, cruz: 'CENTER' });
        celda.appendChild(icono(nombre, 'ColorScheme/onSurface', 24, undefined, conjunto));
        agregar(celda, await texto(nombre, 'TextTheme/bodySmall', 'ColorScheme/onSurfaceVariant', 'nombre'), { ancho: true });
        fila.appendChild(celda);
      }
      iconos.appendChild(fila);
    }
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

let posicion = 0;

function pantalla(nombre) {
  const f = marco({ nombre: nombre, dir: 'V', ancho: 390, alto: 844, fondo: 'ColorScheme/surface', recorta: true });
  f.x = (posicion % 7) * 430;
  f.y = Math.floor(posicion / 7) * 900;
  posicion++;
  return f;
}

function contenido(padre, pad, gap, centrado) {
  const c = marco({ nombre: 'contenido', dir: 'V', pad: pad, gap: gap, recorta: true, alinea: centrado ? 'CENTER' : 'MIN' });
  agregar(padre, c, { ancho: true, alto: true });
  return c;
}

function grupo(padre, gap) {
  const g = marco({ nombre: 'grupo', dir: 'V', gap: gap || 'e8' });
  agregar(padre, g, { ancho: true });
  return g;
}

function centrar(padre, inst) {
  const f = marco({ nombre: 'centrado', dir: 'H', alinea: 'CENTER' });
  f.appendChild(inst);
  agregar(padre, f, { ancho: true });
  return f;
}

function cambiarTextoN(inst, valor, nombre, indice) {
  const lista = inst.findAll(n => n.type === 'TEXT' && n.name === nombre);
  if (lista[indice]) lista[indice].characters = valor;
  return inst;
}

function encabezado(padre, conLogo, titulo, subtitulo) {
  const inst = instancia('EncabezadoAcceso', { ConLogo: conLogo ? 'si' : 'no' });
  cambiarTexto(inst, titulo, 'titulo');
  cambiarTexto(inst, subtitulo, 'subtitulo');
  agregar(padre, inst, { ancho: true });
}

function barra(padre, titulo, volver, refrescar) {
  const inst = instancia('AppBar', { Volver: volver ? 'si' : 'no', Accion: refrescar ? 'refrescar' : 'ninguna' });
  agregar(padre, cambiarTexto(inst, titulo, 'titulo'), { ancho: true });
}

function campo(padre, contenidoCampo, o) {
  const op = o || {};
  const inst = instancia('CampoTexto', { Estado: op.estado || 'vacio', Tipo: op.tipo || 'texto', Icono: op.icono ? 'si' : 'no' });
  cambiarTexto(inst, contenidoCampo);
  if (op.icono) cambiarIcono(inst, op.icono);
  if (op.error) cambiarTexto(inst, op.error, 'ayuda');
  agregar(padre, inst, { ancho: true });
  return inst;
}

function selector(padre, etiquetaCampo, valor) {
  const inst = instancia('DropdownButtonFormField', { Estado: 'default' });
  cambiarTexto(inst, etiquetaCampo, 'etiqueta');
  cambiarTexto(inst, valor, 'valor');
  agregar(padre, inst, { ancho: true });
}

function accion(padre, contenidoBoton, variante, nombreIcono) {
  agregar(padre, boton(contenidoBoton, variante, 'default', nombreIcono), { ancho: true });
}

function navegacion(padre, activo) {
  agregar(padre, instancia('EstructuraPrincipal', { Activo: activo }), { ancho: true });
}

function pie(padre, variante) {
  agregar(padre, instancia('PieEnlace', { Variante: variante }), { ancho: true });
}

function pieBoton(padre, contenidoBoton, nombreIcono) {
  const f = marco({ nombre: 'pie', dir: 'V', pad: [null, 'e24', 'e16', 'e24'] });
  agregar(padre, f, { ancho: true });
  accion(f, contenidoBoton, 'texto', nombreIcono);
}

function vacio(padre, titulo, mensaje, textoBoton, nombreIcono) {
  const inst = instancia('MensajeVacio', { ConBoton: textoBoton ? 'si' : 'no' });
  cambiarIcono(inst, nombreIcono, 64);
  cambiarTexto(inst, titulo, 'titulo');
  if (mensaje) cambiarTexto(inst, mensaje, 'mensaje');
  else ocultar(inst, 'mensaje');
  if (textoBoton) cambiarTexto(inst, textoBoton);
  agregar(padre, inst, { ancho: true });
}

function fallo(padre, mensaje) {
  const inst = instancia('ErrorConReintento', { Estado: 'default' });
  cambiarTexto(inst, mensaje, 'mensaje');
  agregar(padre, inst, { ancho: true });
}

function cargando(padre) {
  agregar(padre, instancia('CircularProgressIndicator', { Tamano: 'grande' }), { ancho: true });
}

function flotante(p, conNavegacion) {
  const fab = instancia('FloatingActionButton', { Variante: 'extendido' });
  p.appendChild(fab);
  fab.layoutPositioning = 'ABSOLUTE';
  fab.x = 390 - 16 - fab.width;
  fab.y = 844 - (conNavegacion ? 80 : 0) - 16 - fab.height;
}

function mensajeInferior(p, mensaje, conNavegacion) {
  const s = cambiarTexto(instancia('SnackBar', { Estado: 'default' }), mensaje);
  p.appendChild(s);
  s.layoutPositioning = 'ABSOLUTE';
  s.x = 0;
  s.y = 844 - (conNavegacion ? 80 : 0) - s.height;
}

function armarInicio(p) {
  encabezado(p, true, 'Trueque U', 'Intercambia objetos y materiales con otros estudiantes.');
  const c = contenido(p, ['e40', 'e24', 'e24', 'e24'], 'e12', true);
  accion(c, 'Iniciar sesión', 'primario');
  accion(c, 'Crear cuenta', 'contorno');
}

function armarIniciarSesion(p, conError) {
  encabezado(p, true, 'Trueque U', 'Qué bueno verte de nuevo');
  const c = contenido(p, 'e24', 'e16', true);
  agregar(c, tp('Inicia sesión', 'subtitulo'), { ancho: true });
  campo(c, conError ? 'ana@universidad.edu' : 'Correo', { icono: 'mail_outline', estado: conError ? 'relleno' : 'vacio' });
  campo(c, conError ? '••••••••' : 'Contraseña', { tipo: 'contrasena', icono: 'lock_outline', estado: conError ? 'relleno' : 'vacio' });
  agregar(c, tp('¿Olvidaste tu contraseña?', 'enlace', 'derecha'), { ancho: true });
  if (conError) agregar(c, cambiarTexto(instancia('BannerError', { Estado: 'default' }), 'Correo o contraseña incorrectos', 'mensaje'), { ancho: true });
  accion(c, 'Iniciar sesión', 'primario');
  pie(p, 'crearCuenta');
}

function armarRegistro(p) {
  encabezado(p, false, 'Crear cuenta', 'Únete a la comunidad de tu campus');
  const c = contenido(p, 'e24', 'e16', true);
  campo(c, 'Nombre completo', { icono: 'person_outline' });
  campo(c, 'Correo', { icono: 'mail_outline' });
  const telefono = grupo(c, 'e4');
  campo(telefono, 'Teléfono (opcional, 8 dígitos)', { icono: 'phone_outlined' });
  agregar(telefono, tp('Solo lo verá la persona con la que acuerdes un trueque. Puedes dejarlo vacío.', 'ayuda'), { ancho: true });
  campo(c, 'Contraseña', { tipo: 'contrasena', icono: 'lock_outline' });
  campo(c, 'Repite la contraseña', { tipo: 'contrasena', icono: 'lock_outline' });
  accion(c, 'Crear cuenta', 'rojo');
  pie(p, 'iniciarSesion');
}

function armarRecuperar(p, enviado) {
  encabezado(p, false, 'Recuperar contraseña', 'Te ayudamos a volver a entrar');
  const c = contenido(p, 'e24', 'e16', true);
  c.appendChild(instancia('IconoCaja', { Icono: 'llave' }));
  agregar(c, tp('Escribe el correo de tu cuenta y te enviaremos una contraseña nueva.'), { ancho: true });
  campo(c, enviado ? 'ana@universidad.edu' : 'Correo', { icono: 'mail_outline', estado: enviado ? 'relleno' : 'vacio' });
  accion(c, 'Enviar contraseña nueva', 'primario');
  if (enviado) agregar(c, instancia('BannerExito', { Estado: 'default' }), { ancho: true });
  pieBoton(p, 'Volver a iniciar sesión', 'arrow_back');
}

function armarFeed(p, estado) {
  agregar(p, instancia('CabeceraFeed', { Estado: 'default' }), { ancho: true });
  agregar(p, instancia('FiltrosFeed', { Estado: estado === 'sinResultados' ? 'conFiltros' : 'sinFiltros' }), { ancho: true });
  const lista = contenido(p, 'e20', 'e16', estado !== 'lista');
  if (estado === 'lista') {
    agregar(lista, instancia('TarjetaFeed', { Estado: 'disponible' }), { ancho: true });
    agregar(lista, instancia('TarjetaFeed', { Estado: 'reservadoPorMi' }), { ancho: true });
  }
  if (estado === 'vacio') vacio(lista, 'No hay publicaciones disponibles', 'Sé el primero en compartir un objeto para intercambiar con la comunidad.', 'Crear publicación', 'feed_outlined');
  if (estado === 'sinResultados') vacio(lista, 'Ninguna publicación coincide con tu búsqueda', null, 'Quitar filtros', 'search_off');
  if (estado === 'error') fallo(lista, 'No se pudieron cargar las publicaciones');
  if (estado === 'cargando') cargando(lista);
  navegacion(p, 'explorar');
  flotante(p, true);
}

function armarMisPublicaciones(p, estado) {
  barra(p, 'Mis publicaciones', false, true);
  const c = contenido(p, 'e24', 'e12', estado === 'vacio');
  if (estado === 'vacio') {
    vacio(c, 'Aún no tienes publicaciones', 'Crea una publicación para intercambiar objetos con otros estudiantes.', 'Crear nueva publicación', 'inventory_2_outlined');
  } else {
    agregar(c, tp('Total: 2', 'suave'), { ancho: true });
    agregar(c, instancia('TarjetaMiPublicacion', { Reservada: 'no' }), { ancho: true });
    agregar(c, instancia('TarjetaMiPublicacion', { Reservada: 'si' }), { ancho: true });
  }
  navegacion(p, 'misPublicaciones');
  flotante(p, true);
  if (estado === 'guardada') mensajeInferior(p, 'Publicación guardada exitosamente', true);
}

function armarOfertas(p, estado) {
  barra(p, 'Ofertas de trueque', false, true);
  const c = contenido(p, 'e24', 'e12', estado === 'vacio');
  agregar(c, instancia('SegmentedButton', { Seleccionado: estado === 'enviadas' ? 'enviadas' : 'recibidas' }), { ancho: true });
  const tarjeta = (e, lado) => agregar(c, instancia('TarjetaOferta', { Estado: e, Lado: lado }), { ancho: true });
  if (estado === 'recibidas') {
    tarjeta('pendiente', 'recibida');
    tarjeta('contraofertada', 'recibida');
  }
  if (estado === 'enviadas') {
    tarjeta('pendiente', 'enviada');
    tarjeta('rechazada', 'enviada');
  }
  if (estado === 'entrega') {
    tarjeta('aceptada', 'recibida');
    tarjeta('completada', 'recibida');
  }
  if (estado === 'vacio') {
    vacio(c, 'Nadie te ha ofrecido un trueque', 'Cuando alguien ofrezca un objeto por una publicación tuya, aparecerá aquí.', 'Explorar publicaciones', 'swap_horiz');
  }
  navegacion(p, 'ofertas');
}

function filaPerfil(card, nombreIcono, titulo, tono) {
  const inst = instancia('FilaLista', { Icono: 'con', Subtitulo: 'sin', Final: 'chevron', Tono: tono || 'normal' });
  cambiarTexto(inst, titulo, 'titulo');
  cambiarIcono(inst, nombreIcono);
  agregar(card, inst, { ancho: true });
}

function armarPerfil(p) {
  barra(p, 'Mi perfil', false, false);
  const c = contenido(p, 'e24', 'e24', true);
  const cabecera = grupo(c, 'e8');
  centrar(cabecera, cambiarTexto(instancia('CircleAvatar', { Tamano: 'grande' }), 'AP'));
  agregar(cabecera, tp('Ana Pérez', 'subtitulo', 'centro'), { ancho: true });
  agregar(cabecera, tp('ana@universidad.edu', 'suave', 'centro'), { ancho: true });
  agregar(cabecera, instancia('ResumenCalificaciones', { Estado: 'conDatos' }), { ancho: true });
  const tarjeta = marco({
    nombre: 'opciones', dir: 'V', fondo: 'TemaTruequeU/blanco', borde: 'ColorScheme/outlineVariant', radio: 'r20', recorta: true,
  });
  agregar(c, tarjeta, { ancho: true });
  const opciones = [
    ['handshake_outlined', 'Intercambios completados'], ['history', 'Historial'], ['notifications_none', 'Avisos'],
    ['folder_shared_outlined', 'Mis datos'], ['key_outlined', 'Cambiar contraseña'],
  ];
  for (const o of opciones) {
    filaPerfil(tarjeta, o[0], o[1]);
    agregar(tarjeta, instancia('Divider', { Estado: 'default' }), { ancho: true });
  }
  filaPerfil(tarjeta, 'delete_outline', 'Eliminar cuenta', 'error');
  accion(c, 'Cerrar sesión', 'contornoRojo', 'logout');
  navegacion(p, 'perfil');
}

function armarPublicacion(p, conFoto) {
  barra(p, 'Nueva publicación', true, false);
  const c = contenido(p, 'e24', 'e16', false);
  campo(c, 'Nombre del objeto');
  campo(c, 'Descripción (opcional)', { tipo: 'multilinea' });
  selector(c, 'Estado del objeto', 'Nuevo');
  selector(c, 'Categoría', 'Otros');
  agregar(c, instancia('FotoPublicacion', { Estado: conFoto ? 'imagen' : 'vacia', Forma: 'ancha' }), { ancho: true });
  accion(c, conFoto ? 'Cambiar foto' : 'Elegir foto', 'contorno');
  if (conFoto) accion(c, 'Quitar foto', 'texto');
  accion(c, 'Guardar', 'primario');
  accion(c, 'Cancelar', 'texto');
}

function armarCambiarContrasena(p, conError) {
  barra(p, 'Cambiar contraseña', false, false);
  const c = contenido(p, 'e24', 'e16', true);
  campo(c, conError ? '••••••••' : 'Contraseña actual', { tipo: 'contrasena', estado: conError ? 'relleno' : 'vacio' });
  campo(c, conError ? '••••••••' : 'Contraseña nueva', { tipo: 'contrasena', estado: conError ? 'relleno' : 'vacio' });
  campo(c, conError ? '••••••' : 'Repite la contraseña nueva', {
    tipo: 'contrasena', estado: conError ? 'error' : 'vacio', error: conError ? 'Las contraseñas no coinciden' : null,
  });
  accion(c, 'Guardar', 'primario');
  accion(c, 'Cancelar', 'texto');
}

function armarIntercambios(p, estado) {
  barra(p, 'Intercambios completados', true, true);
  const c = contenido(p, 'e24', 'e12', estado === 'vacio');
  if (estado === 'vacio') {
    vacio(c, 'Aún no tienes intercambios completados', null, null, 'handshake_outlined');
  } else {
    agregar(c, instancia('TarjetaIntercambio', { Rol: 'entregue' }), { ancho: true });
    agregar(c, instancia('TarjetaIntercambio', { Rol: 'recibi' }), { ancho: true });
  }
  accion(c, 'Volver al perfil', 'texto');
}

function armarHistorial(p, estado) {
  barra(p, 'Historial', true, true);
  const c = contenido(p, 'e24', 'e12', estado !== 'lista');
  const filtro = estado === 'filtroVacio' ? 'reservas' : 'todo';
  agregar(c, instancia('FiltrosHistorial', { Seleccionado: filtro }), { ancho: true });
  if (estado === 'lista') {
    for (const t of ['reservo', 'canceloReserva', 'completo']) agregar(c, instancia('TarjetaHistorial', { Tipo: t }), { ancho: true });
  }
  if (estado === 'vacio') vacio(c, 'Aún no tienes movimientos', 'Cuando reserves o completes un intercambio, aparecerá aquí.', 'Explorar publicaciones', 'history');
  if (estado === 'filtroVacio') vacio(c, 'No hay reservas', 'Todavía no tienes nada en esta lista.', 'Ver todo', 'history');
  accion(c, 'Volver al perfil', 'texto');
}

function armarAvisos(p, estado) {
  barra(p, 'Avisos', true, false);
  const c = contenido(p, 'e24', 'e12', estado === 'vacio');
  if (estado === 'vacio') {
    vacio(c, 'No tienes avisos', 'Aquí aparecerán los cambios importantes en tus trueques.', null, 'notifications_none');
  } else {
    agregar(c, instancia('TarjetaAviso', { Estado: 'noLeida' }), { ancho: true });
    agregar(c, cambiarTexto(instancia('TarjetaAviso', { Estado: 'noLeida' }), 'Ana Pérez reservó tu «Mochila azul»', 'titulo'), { ancho: true });
    agregar(c, cambiarTexto(instancia('TarjetaAviso', { Estado: 'leida' }), 'Se completó tu intercambio de «Libro de cálculo»', 'titulo'), { ancho: true });
  }
  accion(c, 'Volver al perfil', 'texto');
}

function agregarDatos(padre, titulo, lineas, conAccion) {
  const inst = instancia('TarjetaDatos', { Variante: conAccion ? 'conAccion' : 'normal' });
  cambiarTexto(inst, titulo, 'titulo');
  cambiarTexto(inst, lineas, 'lineas');
  agregar(padre, inst, { ancho: true });
}

function armarMisDatos(p, estado) {
  barra(p, 'Mis datos', true, false);
  const c = contenido(p, 'e24', 'e16', estado === 'cargando');
  if (estado === 'cargando') {
    cargando(c);
  } else {
    agregar(c, tp('Esto es lo que la app guarda de ti. Puedes descargarlo cuando quieras.'), { ancho: true });
    filaBotones(c, [boton('Descargar JSON', 'primario', 'default', 'download'), boton('Descargar CSV', 'primario', 'default', 'download')]);
    const lista = grupo(c, 'e8');
    agregarDatos(lista, 'Tu perfil', 'Nombre: Ana Pérez\nCorreo: ana@universidad.edu\nTeléfono: 71234567\nCuenta creada: 2026-09-01', true);
    agregarDatos(lista, 'Tus publicaciones', 'Calculadora científica · disponible\nMochila azul · reservado');
    agregarDatos(lista, 'Ofertas que hiciste', 'Ofreciste "Mochila azul" por "Libro de cálculo" · pendiente');
    agregarDatos(lista, 'Ofertas que recibiste', 'Te ofrecieron "Chaqueta de lana" por "Calculadora científica" · aceptada');
    agregarDatos(lista, 'Calificaciones que diste', '4 de 5 · 2026-11-02 · "Muy puntual y amable"');
    agregarDatos(lista, 'Calificaciones que recibiste', 'Aún no te calificaron.');
    agregarDatos(lista, 'Tu historial', 'Calculadora científica · reservo · 2026-10-20');
    accion(c, 'Volver al perfil', 'texto');
  }
  if (estado === 'descarga') mensajeInferior(p, 'Tus datos se descargaron', false);
}

const PANTALLAS = [
  ['PantallaInicio', armarInicio],
  ['PantallaIniciarSesion', p => armarIniciarSesion(p, false)],
  ['PantallaRegistro', armarRegistro],
  ['PantallaRecuperarContrasena', p => armarRecuperar(p, false)],
  ['PantallaFeedPublicaciones', p => armarFeed(p, 'lista')],
  ['PantallaMisPublicaciones', p => armarMisPublicaciones(p, 'lista')],
  ['PantallaOfertas', p => armarOfertas(p, 'recibidas')],
  ['PantallaPerfil', armarPerfil],
  ['PantallaPublicacion', p => armarPublicacion(p, false)],
  ['PantallaIntercambios', p => armarIntercambios(p, 'lista')],
  ['PantallaHistorial', p => armarHistorial(p, 'lista')],
  ['PantallaAvisos', p => armarAvisos(p, 'lista')],
  ['PantallaMisDatos', p => armarMisDatos(p, 'datos')],
  ['PantallaCambiarContrasena', p => armarCambiarContrasena(p, false)],
  ['PantallaIniciarSesion · error', p => armarIniciarSesion(p, true)],
  ['PantallaRecuperarContrasena · enviado', p => armarRecuperar(p, true)],
  ['PantallaFeedPublicaciones · vacío', p => armarFeed(p, 'vacio')],
  ['PantallaFeedPublicaciones · sin resultados', p => armarFeed(p, 'sinResultados')],
  ['PantallaFeedPublicaciones · error', p => armarFeed(p, 'error')],
  ['PantallaFeedPublicaciones · cargando', p => armarFeed(p, 'cargando')],
  ['PantallaMisPublicaciones · vacío', p => armarMisPublicaciones(p, 'vacio')],
  ['PantallaMisPublicaciones · publicación guardada', p => armarMisPublicaciones(p, 'guardada')],
  ['PantallaOfertas · enviadas', p => armarOfertas(p, 'enviadas')],
  ['PantallaOfertas · entrega y calificación', p => armarOfertas(p, 'entrega')],
  ['PantallaOfertas · vacío', p => armarOfertas(p, 'vacio')],
  ['PantallaPublicacion · con foto', p => armarPublicacion(p, true)],
  ['PantallaIntercambios · vacío', p => armarIntercambios(p, 'vacio')],
  ['PantallaHistorial · vacío', p => armarHistorial(p, 'vacio')],
  ['PantallaHistorial · filtro sin resultados', p => armarHistorial(p, 'filtroVacio')],
  ['PantallaAvisos · vacío', p => armarAvisos(p, 'vacio')],
  ['PantallaMisDatos · cargando', p => armarMisDatos(p, 'cargando')],
  ['PantallaMisDatos · descarga', p => armarMisDatos(p, 'descarga')],
  ['PantallaCambiarContrasena · error', p => armarCambiarContrasena(p, true)],
];

async function construirPantallas() {
  posicion = 0;
  for (const d of PANTALLAS) d[1](pantalla(d[0]));
}

const FEED = p => armarFeed(p, 'lista');
const OFERTAS = p => armarOfertas(p, 'recibidas');
const OFERTAS_ENVIADAS = p => armarOfertas(p, 'enviadas');
const OFERTAS_ENTREGA = p => armarOfertas(p, 'entrega');
const MIS_PUBLICACIONES = p => armarMisPublicaciones(p, 'lista');
const HISTORIAL = p => armarHistorial(p, 'lista');

const ESCENAS = [
  ['confirmarAccion · normal', OFERTAS, () => instancia('confirmarAccion', { Variante: 'normal' })],
  ['confirmarAccion · destructivo', OFERTAS, () => instancia('confirmarAccion', { Variante: 'destructivo' })],
  ['confirmarAccion · cancelar oferta', OFERTAS_ENVIADAS, () => {
    const d = instancia('confirmarAccion', { Variante: 'destructivo' });
    cambiarTexto(d, 'Cancelar oferta', 'titulo');
    cambiarTextoN(d, '¿Cancelas esta oferta? La otra persona ya no podrá aceptarla.', 'texto', 0);
    cambiarTextoN(d, 'Volver', 'texto', 1);
    cambiarTextoN(d, 'Sí, cancelar oferta', 'texto', 2);
    return d;
  }],
  ['mostrarAyudaTrueque', FEED, () => instancia('mostrarAyudaTrueque', { Estado: 'default' })],
  ['pedirCalificacion · sinPuntaje', OFERTAS_ENTREGA, () => instancia('pedirCalificacion', { Estado: 'sinPuntaje' })],
  ['pedirCalificacion · conPuntaje', OFERTAS_ENTREGA, () => instancia('pedirCalificacion', { Estado: 'conPuntaje' })],
  ['pedirCalificacion · error', OFERTAS_ENTREGA, () => instancia('pedirCalificacion', { Estado: 'error' })],
  ['pedirMotivoCancelacion · vacío', OFERTAS_ENTREGA, () => instancia('pedirMotivoCancelacion', { Estado: 'vacio' })],
  ['pedirMotivoCancelacion · con motivo', OFERTAS_ENTREGA, () => instancia('pedirMotivoCancelacion', { Estado: 'conMotivo' })],
  ['pedirDatosEntrega · proponer', OFERTAS_ENTREGA, () => instancia('pedirDatosEntrega', { Variante: 'proponer' })],
  ['pedirDatosEntrega · reprogramar', OFERTAS_ENTREGA, () => instancia('pedirDatosEntrega', { Variante: 'reprogramar' })],
  ['pedirDatosEntrega · contraproponer', OFERTAS_ENTREGA, () => instancia('pedirDatosEntrega', { Variante: 'contraproponer' })],
  ['pedirDatosEntrega · con errores', OFERTAS_ENTREGA, () => instancia('pedirDatosEntrega', { Variante: 'conErrores' })],
  ['mostrarDialogoOferta · ofrecer', FEED, () => instancia('mostrarDialogoOferta', { Tipo: 'ofrecer', Estado: 'conOpciones' })],
  ['mostrarDialogoOferta · ofrecer sin opciones', FEED, () => instancia('mostrarDialogoOferta', { Tipo: 'ofrecer', Estado: 'vacio' })],
  ['mostrarDialogoOferta · contraofertar', OFERTAS, () => instancia('mostrarDialogoOferta', { Tipo: 'contraofertar', Estado: 'conOpciones' })],
  ['mostrarDialogoOferta · contraofertar sin opciones', OFERTAS, () => instancia('mostrarDialogoOferta', { Tipo: 'contraofertar', Estado: 'vacio' })],
  ['DialogoEditarPublicacion · normal', MIS_PUBLICACIONES, () => instancia('DialogoEditarPublicacion', { Estado: 'normal' })],
  ['DialogoEditarPublicacion · guardando', MIS_PUBLICACIONES, () => instancia('DialogoEditarPublicacion', { Estado: 'guardando' })],
  ['DialogoEditarPublicacion · error', MIS_PUBLICACIONES, () => instancia('DialogoEditarPublicacion', { Estado: 'error' })],
  ['DialogoEliminarCuenta · normal', armarPerfil, () => instancia('DialogoEliminarCuenta', { Estado: 'normal' })],
  ['DialogoEliminarCuenta · contraseña incorrecta', armarPerfil, () => instancia('DialogoEliminarCuenta', { Estado: 'error' })],
  ['DialogoHistorial · negociación', OFERTAS, () => instancia('DialogoHistorial', { Tipo: 'negociacion' })],
  ['DialogoHistorial · entrega', OFERTAS_ENTREGA, () => instancia('DialogoHistorial', { Tipo: 'entrega' })],
  ['DialogoHistorial · movimiento', HISTORIAL, () => instancia('DialogoHistorial', { Tipo: 'movimiento' })],
];

async function construirDialogos() {
  posicion = 0;
  for (const e of ESCENAS) {
    const p = pantalla(e[0]);
    e[1](p);
    const velo = marco({
      nombre: 'velo', dir: 'V', ancho: 390, alto: 844, fondo: 'ColorScheme/onSurface', opacidad: 0.32, alinea: 'CENTER', cruz: 'CENTER',
    });
    p.appendChild(velo);
    velo.layoutPositioning = 'ABSOLUTE';
    velo.x = 0;
    velo.y = 0;
    velo.appendChild(e[2]());
  }
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
  const dialogos = await pagina('💬 Diálogos');
  await figma.setCurrentPageAsync(componentes);
  await construirComponentes();
  await figma.setCurrentPageAsync(fundamentos);
  await construirFundamentos();
  await figma.setCurrentPageAsync(pantallas);
  await construirPantallas();
  await figma.setCurrentPageAsync(dialogos);
  await construirDialogos();
  await figma.setCurrentPageAsync(fundamentos);
}

main()
  .then(() => figma.closePlugin('Sistema de diseño TruequeU generado'))
  .catch(error => figma.closePlugin('Error: ' + (error && error.message ? error.message : error)));
