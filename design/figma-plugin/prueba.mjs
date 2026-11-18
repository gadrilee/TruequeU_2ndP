import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const aqui = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(join(aqui, 'tokens.json'), 'utf8'));
const codigo = readFileSync(join(aqui, 'code.js'), 'utf8');
const carpetaLib = join(aqui, '..', '..', 'trueque-u', 'app', 'lib');
const carpetaPantallas = join(carpetaLib, 'pantallas');
const iconos = JSON.parse(readFileSync(join(aqui, 'iconos.json'), 'utf8'));
const iconosMarco = JSON.parse(readFileSync(join(aqui, 'iconos-marco.json'), 'utf8'));
const SIMBOLOS = /[\u2190-\u2BFF\u25A0-\u25FF\u2600-\u27BF]/;

function archivosDart(carpeta) {
  return readdirSync(carpeta, { withFileTypes: true }).flatMap(e => {
    const ruta = join(carpeta, e.name);
    if (e.isDirectory()) return archivosDart(ruta);
    return e.name.endsWith('.dart') ? [ruta] : [];
  });
}

function iconosDeLib() {
  const nombres = new Set();
  for (const archivo of archivosDart(carpetaLib)) {
    for (const m of readFileSync(archivo, 'utf8').matchAll(/Icons\.([a-zA-Z0-9_]+)/g)) nombres.add(m[1]);
  }
  return [...nombres].sort();
}

function clasesDePantallas() {
  const clases = [];
  for (const archivo of readdirSync(carpetaPantallas).filter(a => a.endsWith('.dart'))) {
    const dart = readFileSync(join(carpetaPantallas, archivo), 'utf8');
    for (const m of dart.matchAll(/^class (Pantalla\w+)\s+extends\s+(StatelessWidget|StatefulWidget)/gm)) clases.push(m[1]);
  }
  return clases.sort();
}

const CAMPOS_NUMERICOS = [
  'width', 'height', 'itemSpacing', 'paddingLeft', 'paddingRight', 'paddingTop', 'paddingBottom',
  'topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius', 'fontSize',
];
const ALCANCES_VALIDOS = [
  'ALL_SCOPES', 'TEXT_CONTENT', 'CORNER_RADIUS', 'WIDTH_HEIGHT', 'GAP', 'ALL_FILLS', 'FRAME_FILL',
  'SHAPE_FILL', 'TEXT_FILL', 'STROKE_COLOR', 'EFFECT_COLOR', 'FONT_SIZE', 'FONT_FAMILY',
];
const CONTENEDORES = ['DOCUMENT', 'PAGE', 'FRAME', 'COMPONENT', 'COMPONENT_SET', 'INSTANCE'];

function crearMundo(opciones) {
  let contador = 0;
  const nuevoId = () => 'id' + ++contador;
  const fuentes = new Set();
  const mundo = { colecciones: [], variables: [], estilos: [], paginas: [], actual: null, mensaje: null, opciones };

  const grisSinEnlace = () => [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];

  class Nodo {
    constructor(tipo) {
      this.type = tipo;
      this.id = nuevoId();
      this.name = tipo;
      this.children = [];
      this.parent = null;
      this.boundVariables = {};
      this.width = 100;
      this.height = 100;
      this.x = 0;
      this.y = 0;
      this.layoutMode = 'NONE';
      this.fills = tipo === 'PAGE' || tipo === 'DOCUMENT' ? [] : grisSinEnlace();
      this.strokes = tipo === 'COMPONENT_SET' ? [{ type: 'SOLID', color: { r: 0.6, g: 0.3, b: 1 } }] : [];
      this.itemSpacing = 0;
      this.paddingTop = 0;
      this.paddingRight = 0;
      this.paddingBottom = 0;
      this.paddingLeft = 0;
      this.topLeftRadius = 0;
      this.topRightRadius = 0;
      this.bottomLeftRadius = 0;
      this.bottomRightRadius = 0;
    }
    get fills() {
      return this._fills;
    }
    set fills(valor) {
      this._fills = !opciones.sinGradiente ? valor : valor.map(p => {
        if (p.type !== 'GRADIENT_LINEAR') return p;
        return Object.assign({}, p, { gradientStops: p.gradientStops.map(s => ({ position: s.position, color: s.color })) });
      });
    }
    appendChild(hijo) {
      assert(CONTENEDORES.includes(this.type), 'no se puede agregar a ' + this.type);
      if (hijo.parent) hijo.parent.children = hijo.parent.children.filter(x => x !== hijo);
      this.children.push(hijo);
      hijo.parent = this;
    }
    remove() {
      if (this.parent) this.parent.children = this.parent.children.filter(x => x !== this);
      this.parent = null;
    }
    resize(ancho, alto) {
      this.width = ancho;
      this.height = alto;
    }
    todos() {
      return this.children.flatMap(h => [h, ...h.todos()]);
    }
    findAll(fn) {
      return this.todos().filter(fn);
    }
    findOne(fn) {
      return this.todos().find(fn) || null;
    }
    setProperties(props) {
      assert.equal(this.type, 'INSTANCE', 'setProperties solo en instancias');
      const conjunto = this.mainComponent.parent;
      assert(conjunto && conjunto.type === 'COMPONENT_SET', 'la instancia no es de una variante');
      const variante = conjunto.children.find(h => {
        const partes = h.name.split(', ');
        return Object.keys(props).every(k => partes.includes(k + '=' + props[k]));
      });
      assert(variante, 'variante inexistente ' + JSON.stringify(props));
      this.mainComponent = variante;
      this.children = variante.children.map(h => copia(h, this));
    }
    setBoundVariable(campo, v) {
      assert(v && v.id, 'variable invalida en ' + campo);
      assert(CAMPOS_NUMERICOS.includes(campo), 'campo no enlazable: ' + campo);
      assert.equal(v.resolvedType, 'FLOAT', campo + ' requiere variable FLOAT');
      this.boundVariables[campo] = { type: 'VARIABLE_ALIAS', id: v.id };
    }
    set layoutSizingHorizontal(valor) {
      if (valor === 'FILL') {
        assert(this.parent && this.parent.layoutMode !== 'NONE', 'FILL requiere padre con auto layout: ' + this.name);
      }
      this._sh = valor;
    }
    get layoutSizingHorizontal() {
      return this._sh;
    }
    set layoutSizingVertical(valor) {
      if (valor === 'FILL') {
        assert(this.parent && this.parent.layoutMode !== 'NONE', 'FILL requiere padre con auto layout: ' + this.name);
      }
      this._sv = valor;
    }
    get layoutSizingVertical() {
      return this._sv;
    }
  }

  const copia = (origen, padre) => {
    const n = new Nodo(origen.type === 'COMPONENT' ? 'INSTANCE' : origen.type);
    for (const k of Object.keys(origen)) {
      if (['id', 'children', 'parent', 'type', 'mainComponent'].includes(k)) continue;
      n[k] = JSON.parse(JSON.stringify(origen[k] === undefined ? null : origen[k]));
    }
    n.layoutMode = origen.layoutMode;
    n._sh = origen._sh;
    n._sv = origen._sv;
    n.parent = padre;
    n.textStyleId = origen.textStyleId;
    n.characters = origen.characters;
    if (origen.type === 'INSTANCE') n.mainComponent = origen.mainComponent;
    n.children = origen.children.map(h => copia(h, n));
    return n;
  };

  class Componente extends Nodo {
    createInstance() {
      const inst = copia(this, null);
      inst.mainComponent = this;
      figmaFalso.currentPage.appendChild(inst);
      return inst;
    }
  }

  class ConjuntoComponentes extends Nodo {
    constructor() {
      super('COMPONENT_SET');
      this.propiedades = {};
    }
    addComponentProperty(nombre, tipo, valor) {
      assert.equal(tipo, 'TEXT');
      assert(!this.propiedades[nombre], 'propiedad repetida ' + nombre);
      const clave = nombre + '#' + nuevoId();
      this.propiedades[nombre] = { clave, valor };
      return clave;
    }
  }

  class Texto extends Nodo {
    constructor() {
      super('TEXT');
      this._fuente = null;
      this._caracteres = '';
      this.textStyleId = '';
    }
    set fontName(valor) {
      assert(fuentes.has(valor.family + '/' + valor.style), 'fuente sin cargar: ' + JSON.stringify(valor));
      this._fuente = valor;
    }
    get fontName() {
      return this._fuente;
    }
    set characters(valor) {
      if (valor === undefined) return;
      assert(this._fuente, 'characters sin fontName cargada');
      this._caracteres = valor;
    }
    get characters() {
      return this._caracteres;
    }
    async setTextStyleIdAsync(id) {
      assert(mundo.estilos.some(e => e.id === id), 'estilo inexistente');
      this.textStyleId = id;
    }
    set componentPropertyReferences(valor) {
      this._refs = valor;
    }
    get componentPropertyReferences() {
      return this._refs;
    }
  }

  const alta = (nodo) => {
    figmaFalso.currentPage.appendChild(nodo);
    return nodo;
  };

  const figmaFalso = {
    get currentPage() {
      return mundo.actual;
    },
    root: new Nodo('DOCUMENT'),
    notify() {},
    closePlugin(mensaje) {
      mundo.mensaje = mensaje || '';
      mundo.resolverFin();
    },
    async loadFontAsync(f) {
      if (opciones.sinSemiBold && f.style === 'SemiBold') throw new Error('Fuente no disponible: ' + f.style);
      fuentes.add(f.family + '/' + f.style);
    },
    createPage() {
      const p = new Nodo('PAGE');
      p.loadAsync = async () => {};
      figmaFalso.root.appendChild(p);
      mundo.paginas.push(p);
      return p;
    },
    async setCurrentPageAsync(p) {
      mundo.actual = p;
    },
    createFrame: () => alta(new Nodo('FRAME')),
    createRectangle: () => alta(new Nodo('RECTANGLE')),
    createEllipse: () => alta(new Nodo('ELLIPSE')),
    createVector: () => alta(new Nodo('VECTOR')),
    createNodeFromSvg(svg) {
      assert(typeof svg === 'string' && svg.startsWith('<svg'), 'SVG invalido');
      const caja = alta(new Nodo('FRAME'));
      caja.resize(24, 24);
      caja.fuenteSvg = svg;
      const trazados = [...svg.matchAll(/<path /g)].length;
      assert(trazados > 0, 'SVG sin trazados');
      for (let i = 0; i < trazados; i++) {
        const v = new Nodo('VECTOR');
        caja.appendChild(v);
      }
      return caja;
    },
    flatten(nodos, padre) {
      assert(nodos.length > 0, 'flatten sin nodos');
      const origenSvg = nodos[0].parent && nodos[0].parent.fuenteSvg;
      const vector = new Nodo('VECTOR');
      vector.fuenteSvg = origenSvg;
      nodos.forEach(n => n.remove());
      padre.appendChild(vector);
      return vector;
    },
    createText: () => alta(new Texto()),
    createComponent: () => alta(new Componente('COMPONENT')),
    combineAsVariants(comps, padre) {
      assert(comps.length >= 1);
      const claves = new Set();
      const nombres = new Set();
      for (const c of comps) {
        assert.equal(c.type, 'COMPONENT');
        assert(!nombres.has(c.name), 'variante repetida ' + c.name);
        nombres.add(c.name);
        claves.add(c.name.split(', ').map(p => p.split('=')[0]).join('|'));
      }
      assert.equal(claves.size, 1, 'variantes con propiedades distintas');
      const conjunto = new ConjuntoComponentes();
      padre.appendChild(conjunto);
      comps.forEach(c => conjunto.appendChild(c));
      return conjunto;
    },
    createTextStyle() {
      const e = {
        id: 'S' + nuevoId(),
        name: '',
        boundVariables: {},
        setBoundVariable(campo, v) {
          assert(['fontSize', 'fontFamily'].includes(campo), 'campo de estilo no enlazable: ' + campo);
          assert.equal(v.resolvedType, campo === 'fontSize' ? 'FLOAT' : 'STRING', campo);
          this.boundVariables[campo] = { type: 'VARIABLE_ALIAS', id: v.id };
        },
      };
      mundo.estilos.push(e);
      return e;
    },
    async getLocalTextStylesAsync() {
      return mundo.estilos;
    },
    variables: {
      createVariableCollection(nombre) {
        const c = {
          id: 'C' + nuevoId(),
          name: nombre,
          modes: [{ modeId: 'M' + nuevoId(), name: 'Mode 1' }],
          remove() {
            mundo.colecciones.splice(mundo.colecciones.indexOf(this), 1);
            mundo.variables = mundo.variables.filter(v => v.variableCollectionId !== this.id);
          },
        };
        mundo.colecciones.push(c);
        return c;
      },
      createVariable(nombre, coleccion, tipo) {
        assert(coleccion && coleccion.id, 'se requiere la coleccion');
        assert(['COLOR', 'FLOAT', 'STRING'].includes(tipo));
        const v = {
          id: 'V' + nuevoId(),
          name: nombre,
          variableCollectionId: coleccion.id,
          resolvedType: tipo,
          valores: {},
          _alcances: [],
          set scopes(a) {
            a.forEach(x => assert(ALCANCES_VALIDOS.includes(x), 'alcance invalido ' + x));
            this._alcances = a;
          },
          get scopes() {
            return this._alcances;
          },
          description: '',
          setValueForMode(modo, valor) {
            if (valor && valor.type === 'VARIABLE_ALIAS') this.valores[modo] = valor;
            else if (tipo === 'COLOR') {
              assert(['r', 'g', 'b', 'a'].every(k => typeof valor[k] === 'number'));
              this.valores[modo] = valor;
            } else if (tipo === 'STRING') {
              assert.equal(typeof valor, 'string');
              this.valores[modo] = valor;
            } else {
              assert.equal(typeof valor, 'number');
              this.valores[modo] = valor;
            }
          },
        };
        mundo.variables.push(v);
        return v;
      },
      async getLocalVariableCollectionsAsync() {
        return mundo.colecciones;
      },
      async getLocalVariablesAsync() {
        return mundo.variables;
      },
      createVariableAlias(v) {
        return { type: 'VARIABLE_ALIAS', id: v.id };
      },
      setBoundVariableForPaint(paint, campo, v) {
        assert.equal(paint.type, 'SOLID');
        assert.equal(campo, 'color');
        assert.equal(v.resolvedType, 'COLOR');
        return Object.assign({}, paint, { boundVariables: { color: { type: 'VARIABLE_ALIAS', id: v.id } } });
      },
    },
  };

  mundo.figma = figmaFalso;
  mundo.pagina1 = figmaFalso.createPage();
  mundo.pagina1.name = 'Page 1';
  mundo.actual = mundo.pagina1;
  if (opciones.conColeccionAntigua) {
    const antigua = figmaFalso.variables.createVariableCollection('ColorScheme');
    const primitiva = figmaFalso.variables.createVariable('primary', antigua, 'COLOR');
    primitiva.setValueForMode(antigua.modes[0].modeId, { r: 0, g: 0, b: 0, a: 1 });
  }
  return mundo;
}

async function ejecutar(mundo) {
  const fin = new Promise(resolver => {
    mundo.resolverFin = resolver;
  });
  const contexto = vm.createContext({ figma: mundo.figma, console });
  vm.runInContext(codigo, contexto);
  await fin;
  return contexto;
}

function todosLosNodos(mundo) {
  return mundo.paginas.flatMap(p => p.todos());
}

function pagina(mundo, nombre) {
  return mundo.paginas.find(p => p.name === nombre);
}

const plano = valor => JSON.parse(JSON.stringify(valor));
const reporte = [];
let registrando = true;
function ok(texto) {
  if (registrando) reporte.push(texto);
}

function revisar(mundo, contexto) {
  assert(!mundo.mensaje.startsWith('Error'), mundo.mensaje);

  const nombres = mundo.colecciones.map(c => c.name).sort();
  assert.deepEqual(nombres, ['Espacios', 'Radios', 'TemaTruequeU', 'Tipos']);
  const tipoDe = (coleccion, valor) => (coleccion === 'TemaTruequeU' ? (valor.startsWith('#') ? 'COLOR' : 'STRING') : 'FLOAT');
  const tipo = { TemaTruequeU: 'COLOR', Espacios: 'FLOAT', Radios: 'FLOAT', Tipos: 'FLOAT' };
  let contadas = 0;
  const hexARgb = hex => {
    const n = parseInt(hex.slice(1), 16);
    return { r: ((n >> 16) & 255) / 255, g: ((n >> 8) & 255) / 255, b: (n & 255) / 255, a: 1 };
  };
  const porRuta = {};
  for (const c of mundo.colecciones) {
    for (const v of mundo.variables.filter(x => x.variableCollectionId === c.id)) porRuta[c.name + '/' + v.name] = v;
  }
  for (const coleccion of Object.keys(tipo)) {
    const modo = mundo.colecciones.find(c => c.name === coleccion).modes[0].modeId;
    for (const [campo, valor] of Object.entries(tokens[coleccion])) {
      const v = porRuta[coleccion + '/' + campo];
      assert(v, 'falta la variable ' + coleccion + '/' + campo);
      assert.equal(v.resolvedType, tipoDe(coleccion, String(valor)));
      assert(v.scopes.length > 0);
      assert.equal(v.description, coleccion + '.' + campo);
      assert.notEqual(plano(v.valores[modo]).type, 'VARIABLE_ALIAS', 'cadena de alias en ' + coleccion + '/' + campo);
      if (coleccion === 'TemaTruequeU' && valor.startsWith('#')) {
        assert.deepEqual(plano(v.valores[modo]), hexARgb(valor));
      } else if (coleccion === 'TemaTruequeU') {
        assert.equal(v.valores[modo], valor);
        assert.deepEqual(plano(v.scopes), ['FONT_FAMILY']);
      } else {
        assert.equal(v.valores[modo], valor);
      }
      contadas++;
    }
  }
  assert.equal(mundo.variables.length, contadas);
  ok(`variables: ${contadas} (las claves de tokens.json salvo ColorScheme, que es solo documentacion; sin duplicados ni alias)`);

  assert(!mundo.colecciones.some(c => c.name === 'ColorScheme'), 'la coleccion ColorScheme no debe existir');
  assert.deepEqual(Object.keys(tokens.ColorScheme).filter(r => !tokens.ColorScheme[r].startsWith('TemaTruequeU/')), []);
  const coleccionesColor = mundo.colecciones.filter(c => mundo.variables.some(v => v.variableCollectionId === c.id && v.resolvedType === 'COLOR'));
  assert.deepEqual(coleccionesColor.map(c => c.name), ['TemaTruequeU']);
  ok('una sola coleccion de color: TemaTruequeU; no existe ColorScheme; la fuente es la variable STRING TemaTruequeU/fuente = ' + tokens.TemaTruequeU.fuente);

  const COLECCIONES_TEXTO = ['TextTheme', 'TextosTruequeU', 'TextoDerivado'];
  const nombresEstilo = COLECCIONES_TEXTO.flatMap(c => Object.keys(tokens[c]).map(k => c + '/' + k));
  assert.equal(mundo.estilos.length, nombresEstilo.length);
  assert.deepEqual(mundo.estilos.map(e => e.name).sort(), [...nombresEstilo].sort());
  const nombrePeso = { 400: 'Regular', 500: 'Medium', 600: mundo.opciones.sinSemiBold ? 'Bold' : 'SemiBold', 700: 'Bold' };
  let enlazados = 0;
  for (const e of mundo.estilos) {
    const [coleccion, campo] = e.name.split('/');
    const def = tokens[coleccion][campo];
    const tamano = typeof def.fontSize === 'string' ? tokens.Tipos[def.fontSize.split('/')[1]] : def.fontSize;
    assert.equal(e.fontName.family, tokens.TemaTruequeU.fuente, e.name);
    assert.equal(e.boundVariables.fontFamily.id, porRuta['TemaTruequeU/fuente'].id, 'fontFamily sin enlazar en ' + e.name);
    assert(e.description.includes(tokens.TemaTruequeU.fuente), e.name);
    assert.equal(e.fontName.style, nombrePeso[def.fontWeight], e.name);
    assert.equal(e.fontSize, tamano, e.name);
    const esperadaAltura = def.height === null ? { unit: 'AUTO' } : { unit: 'PIXELS', value: Math.round(tamano * def.height * 100) / 100 };
    assert.deepEqual(plano(e.lineHeight), esperadaAltura, e.name);
    assert.deepEqual(plano(e.letterSpacing), { unit: 'PIXELS', value: def.letterSpacing || 0 }, e.name);
    const alias = typeof def.fontSize === 'string' ? def.fontSize : 'Tipos/t' + tamano;
    if (tokens.Tipos[alias.split('/')[1]] === tamano) {
      assert.equal(e.boundVariables.fontSize.id, porRuta[alias].id, 'fontSize sin enlazar en ' + e.name);
      enlazados++;
    } else {
      assert(!e.boundVariables.fontSize, 'fontSize enlazado sin token en ' + e.name);
    }
  }
  for (const campo of Object.keys(tokens.TextosTruequeU)) {
    const e = mundo.estilos.find(x => x.name === 'TextosTruequeU/' + campo);
    assert.equal(e.boundVariables.fontSize.id, porRuta[tokens.TextosTruequeU[campo].fontSize].id);
  }
  ok(`estilos de texto: ${mundo.estilos.length} (TextTheme ${Object.keys(tokens.TextTheme).length}, TextosTruequeU ${Object.keys(tokens.TextosTruequeU).length}, TextoDerivado ${Object.keys(tokens.TextoDerivado).length}) con familia, peso, altura de linea y espaciado de tokens.json; ${enlazados} con tamano enlazado a Tipos`);

  assert.deepEqual(mundo.paginas.filter(p => p.name !== 'Page 1').map(p => p.name), ['🎨 Fundamentos', '🧩 Componentes', '📱 Pantallas', '💬 Diálogos']);

  const conjuntos = pagina(mundo, '🧩 Componentes').children.filter(n => n.type === 'COMPONENT_SET');
  assert(conjuntos.length >= 10);
  const esperados = [
    'Icono', 'IconoMarco', 'LogoTruequeU', 'BotonCarga', 'CampoTexto', 'BannerError', 'ChipEstado', 'Etiqueta', 'Estrellas', 'FotoPublicacion',
    'MensajeVacio', 'ErrorConReintento', 'FiltrosFeed', 'TarjetaFeed', 'TarjetaMiPublicacion', 'EncabezadoAcceso', 'EstructuraPrincipal',
    'TextoPantalla', 'Divider', 'AppBar', 'FloatingActionButton', 'SnackBar', 'CircleAvatar', 'CircularProgressIndicator',
    'DropdownButtonFormField', 'IconoCaja', 'BannerExito', 'PieEnlace', 'CabeceraFeed', 'SegmentedButton', 'FilaLista',
    'ResumenCalificaciones', 'BloqueCalificacion', 'BloqueEntrega', 'TarjetaIntercambio', 'ChipEstadoOferta', 'TarjetaOferta',
    'FiltrosHistorial', 'TarjetaHistorial', 'TarjetaAviso', 'TarjetaDatos', 'confirmarAccion', 'mostrarAyudaTrueque',
    'pedirCalificacion', 'pedirMotivoCancelacion', 'pedirDatosEntrega', 'mostrarDialogoOferta', 'DialogoEditarPublicacion',
    'DialogoEliminarCuenta', 'DialogoHistorial',
  ];
  assert.deepEqual(conjuntos.map(c => c.name), esperados);
  const detalle = conjuntos.map(c => `${c.name}(${c.children.length})`).join(', ');
  ok(`component sets: ${conjuntos.length} -> ${detalle}`);

  const todos = todosLosNodos(mundo);
  const esDeTema = id => {
    const v = mundo.variables.find(x => x.id === id);
    return !!v && v.resolvedType === 'COLOR' && mundo.colecciones.find(c => c.id === v.variableCollectionId).name === 'TemaTruequeU';
  };
  let solidos = 0;
  let degradados = 0;
  for (const n of todos) {
    for (const lista of [n.fills, n.strokes]) {
      for (const p of lista) {
        if (p.type === 'SOLID') {
          assert(p.boundVariables && p.boundVariables.color, `paint SOLID sin variable en ${n.type} ${n.name}`);
          assert(esDeTema(p.boundVariables.color.id), `color enlazado fuera de TemaTruequeU en ${n.type} ${n.name}`);
          solidos++;
        } else if (p.type === 'GRADIENT_LINEAR') {
          assert(p.gradientStops.every(s => s.boundVariables && s.boundVariables.color), 'degradado sin variables en ' + n.name);
          assert(p.gradientStops.every(s => esDeTema(s.boundVariables.color.id)), 'parada enlazada fuera de TemaTruequeU en ' + n.name);
          degradados++;
        } else {
          assert.fail('paint inesperado ' + p.type);
        }
      }
    }
  }
  ok(`paints SOLID revisados: ${solidos}, todos con variable enlazada; degradados con paradas enlazadas: ${degradados}`);

  const textos = todos.filter(n => n.type === 'TEXT');
  assert(textos.every(t => t.textStyleId));
  ok(`nodos de texto con estilo de texto de tokens.json: ${textos.length}/${textos.length}`);

  const sinFundamentos = mundo.paginas.filter(p => !['Page 1', '🎨 Fundamentos'].includes(p.name)).flatMap(p => p.todos());
  const usados = new Set(sinFundamentos.filter(n => n.type === 'TEXT').map(t => mundo.estilos.find(e => e.id === t.textStyleId).name));
  for (const campo of Object.keys(tokens.TextoDerivado)) assert(usados.has('TextoDerivado/' + campo), 'estilo derivado sin uso: ' + campo);
  const rolesUsados = Object.keys(tokens.TextTheme).filter(r => usados.has('TextTheme/' + r));
  assert(rolesUsados.length >= 5, rolesUsados.join());
  for (const ruta of Object.values(tokens.Contextos)) assert(nombresEstilo.includes(ruta), 'el contexto apunta a un estilo inexistente: ' + ruta);
  ok(`tipografia: los ${Object.keys(tokens.TextoDerivado).length} estilos derivados y ${rolesUsados.length} roles de TextTheme se usan en nodos (${rolesUsados.join(', ')})`);

  const simbolos = textos.filter(t => SIMBOLOS.test(t.characters));
  assert.deepEqual(simbolos.map(t => t.name + ': ' + t.characters), [], 'texto con glifos de simbolo en vez de iconos');
  ok('ningun nodo de texto contiene glifos de simbolo (rangos U+2190-2BFF, U+25A0-25FF, U+2600-27BF)');

  const iconosLib = iconosDeLib();
  const variantesDe = nombre => conjuntos.find(c => c.name === nombre).children.map(h => h.name.replace(/^nombre=/, '')).sort();
  assert.deepEqual(Object.keys(iconos).sort(), iconosLib, 'iconos.json no coincide con los Icons.* de lib');
  assert.deepEqual(variantesDe('Icono'), iconosLib, 'las variantes de Icono no coinciden con los Icons.* de lib');
  assert.deepEqual(variantesDe('IconoMarco'), Object.keys(iconosMarco).sort());
  const compIconos = conjuntos.filter(c => c.name === 'Icono' || c.name === 'IconoMarco').flatMap(c => c.children);
  for (const comp of compIconos) {
    assert.equal(comp.width, 24);
    assert.equal(comp.height, 24);
    const vectores = comp.children.filter(h => h.type === 'VECTOR');
    assert.equal(vectores.length, 1, 'el icono debe ser un solo vector: ' + comp.name);
    assert(vectores[0].fuenteSvg, 'vector sin SVG de origen: ' + comp.name);
    assert(vectores[0].fills[0].boundVariables.color, 'relleno del icono sin variable: ' + comp.name);
    assert(esDeTema(vectores[0].fills[0].boundVariables.color.id), 'relleno del icono fuera de TemaTruequeU: ' + comp.name);
    assert.equal(comp.name.replace(/^nombre=/, ''), iconosLib.concat(Object.keys(iconosMarco)).find(n => comp.name === 'nombre=' + n));
  }
  const instanciasIcono = todos.filter(n => n.type === 'INSTANCE' && n.name === 'icono');
  assert(instanciasIcono.length > 100);
  const sinCatalogo = sinFundamentos.filter(n => n.type === 'INSTANCE' && n.name === 'icono').length;
  const tamanosValidos = [14, 16, 18, 20, 24, 28, 36, 64];
  for (const inst of instanciasIcono) {
    const vector = inst.findOne(n => n.type === 'VECTOR');
    assert(vector, 'instancia de icono sin vector');
    assert(vector.fills.length === 1 && vector.fills[0].type === 'SOLID' && vector.fills[0].boundVariables.color, 'relleno de icono sin variable');
    assert(tamanosValidos.includes(inst.width) && inst.width === inst.height, 'tamano de icono inesperado: ' + inst.width);
  }
  const nombresUsadosEnInstancias = new Set(sinFundamentos.filter(n => n.type === 'INSTANCE' && n.name === 'icono').map(i => i.mainComponent.name.replace(/^nombre=/, '')));
  ok(`iconos: Icons.* de lib (${iconosLib.length}) == iconos.json == variantes de Icono; ${Object.keys(iconosMarco).length} del framework en IconoMarco; ${instanciasIcono.length} instancias (${sinCatalogo} fuera del catalogo de Fundamentos), ${nombresUsadosEnInstancias.size} iconos distintos usados en componentes, pantallas y dialogos, todas con relleno enlazado y tamano entre ${tamanosValidos.join('/')}`);

  const contenedores = todos.filter(n => ['FRAME', 'COMPONENT'].includes(n.type) && !n.parent.type.startsWith('INSTANCE'));
  assert(contenedores.every(f => f.layoutMode !== 'NONE'));
  for (const f of todos.filter(n => ['FRAME', 'COMPONENT', 'RECTANGLE'].includes(n.type))) {
    for (const campo of ['itemSpacing', 'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft', 'topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius']) {
      if (f[campo] > 0) assert(f.boundVariables[campo], `${campo} sin variable en ${f.name}`);
    }
  }
  ok(`auto layout en ${contenedores.length} marcos/componentes; todo padding, separacion y radio > 0 esta enlazado`);

  const conTexto = conjuntos.filter(c => Object.keys(c.propiedades).length > 0).map(c => c.name);
  assert(conTexto.length >= 5);
  ok('propiedades de texto en: ' + conTexto.join(', '));

  assert.throws(() => contexto.pintura('#FF0000'), /no es un token/);
  assert.throws(() => contexto.pintura('ColorScheme/primary'), /no es un token/);
  assert.throws(() => contexto.pintura('TemaTruequeU/noExiste'), /Token inexistente/);
  assert.throws(() => contexto.pintura('TemaTruequeU/fuente'), /Token inexistente/);
  ok('pintura() rechaza colores que no son de TemaTruequeU y la fuente usada como color');

  const fundamentos = pagina(mundo, '🎨 Fundamentos');
  const textosFundamentos = fundamentos.todos().filter(n => n.type === 'TEXT').map(t => t.characters);
  const coloresTema = Object.keys(tokens.TemaTruequeU).filter(k => tokens.TemaTruequeU[k].startsWith('#'));
  assert.equal(textosFundamentos.filter(t => t === 'Paleta TemaTruequeU').length, 1);
  assert(!textosFundamentos.some(t => /^Paleta ·/.test(t) || t.includes('ColorScheme')), 'Fundamentos menciona ColorScheme o una segunda paleta');
  for (const campo of coloresTema) {
    for (const esperado of ['TemaTruequeU/' + campo, tokens.TemaTruequeU[campo], 'TemaTruequeU.' + campo]) {
      assert(textosFundamentos.includes(esperado), 'falta en la paleta: ' + esperado);
    }
  }
  assert.equal(fundamentos.todos().filter(n => n.name === 'color').length, coloresTema.length);
  assert(textosFundamentos.includes('Tipografía · ' + tokens.TemaTruequeU.fuente), 'falta el titulo con el nombre de la fuente');
  assert(textosFundamentos.some(t => t.includes('TemaTruequeU/fuente = ' + tokens.TemaTruequeU.fuente)));
  const lineasTipo = textosFundamentos.filter(t => t.includes(' · ' + tokens.TemaTruequeU.fuente + ' · '));
  assert.equal(lineasTipo.length, Object.keys(tokens.TextTheme).length + Object.keys(tokens.TextosTruequeU).length + Object.keys(tokens.TextoDerivado).length);
  assert(lineasTipo.every(t => /· (Regular|Medium|SemiBold|Bold) · [\d.]+ px · altura /.test(t)), 'una linea de tipografia sin familia, peso, tamano o altura');
  ok(`Fundamentos: una sola paleta "Paleta TemaTruequeU" con ${coloresTema.length} muestras (nombre, hex e identificador Dart) y "Tipografía · ${tokens.TemaTruequeU.fuente}" con ${lineasTipo.length} estilos (familia, peso, tamano, altura)`);

  const bases = [
    'PantallaInicio', 'PantallaIniciarSesion', 'PantallaRegistro', 'PantallaRecuperarContrasena',
    'PantallaFeedPublicaciones', 'PantallaMisPublicaciones', 'PantallaOfertas', 'PantallaPerfil',
    'PantallaPublicacion', 'PantallaIntercambios', 'PantallaHistorial', 'PantallaAvisos', 'PantallaMisDatos', 'PantallaCambiarContrasena',
  ];
  const clases = clasesDePantallas();
  assert(clases.includes('PantallaPublicacion'), 'no se encontro la pantalla de Publicacion.dart');
  assert.deepEqual([...bases].sort(), clases, 'las pantallas de Figma y las de lib/pantallas no coinciden');
  const requeridos = [
    'PantallaFeedPublicaciones · vacío', 'PantallaOfertas · enviadas', 'PantallaAvisos · vacío',
  ];

  const revisarPagina = (nombrePagina) => {
    const lista = pagina(mundo, nombrePagina).children;
    let instancias = 0;
    for (const pantalla of lista) {
      assert.equal(pantalla.type, 'FRAME', 'hijo de pagina que no es marco: ' + pantalla.name);
      assert.equal(pantalla.width, 390);
      assert.equal(pantalla.height, 844);
      assert.equal(pantalla.layoutMode, 'VERTICAL');
      const propios = [];
      const recorrer = n => {
        for (const h of n.children) {
          propios.push(h);
          if (h.type !== 'INSTANCE') recorrer(h);
        }
      };
      recorrer(pantalla);
      assert(propios.every(h => ['FRAME', 'INSTANCE'].includes(h.type)), 'pantalla con nodos ajenos: ' + pantalla.name);
      instancias += propios.filter(h => h.type === 'INSTANCE').length;
    }
    return { lista, instancias };
  };

  const pantallas = revisarPagina('📱 Pantallas');
  const nombresPantallas = pantallas.lista.map(p => p.name);
  for (const clase of clases) assert(nombresPantallas.includes(clase), 'la pantalla Flutter ' + clase + ' no tiene marco con ese nombre en Figma');
  assert.deepEqual(nombresPantallas.slice(0, bases.length), bases);
  for (const extra of nombresPantallas.slice(bases.length)) {
    assert(bases.some(b => extra.startsWith(b + ' · ')), 'marco de estado sin pantalla base: ' + extra);
  }
  for (const nombre of requeridos) assert(nombresPantallas.includes(nombre), 'falta el marco ' + nombre);
  assert.equal(new Set(nombresPantallas).size, nombresPantallas.length, 'nombres de pantalla repetidos');
  ok(`pantallas: las ${clases.length} clases Pantalla* de lib/pantallas tienen marco; ${bases.length} base y ${nombresPantallas.length - bases.length} de estado, todas de 390x844, solo FRAME e INSTANCE (${pantallas.instancias} instancias)`);

  const dialogos = revisarPagina('💬 Diálogos');
  const nombresDialogos = [
    'confirmarAccion', 'mostrarAyudaTrueque', 'pedirCalificacion', 'pedirMotivoCancelacion', 'pedirDatosEntrega',
    'mostrarDialogoOferta', 'DialogoEditarPublicacion', 'DialogoEliminarCuenta', 'DialogoHistorial',
  ];
  for (const nombre of nombresDialogos) {
    assert(dialogos.lista.some(p => p.name === nombre || p.name.startsWith(nombre + ' · ')), 'falta el marco del dialogo ' + nombre);
  }
  for (const marcoDialogo of dialogos.lista) {
    const velo = marcoDialogo.children.find(h => h.name === 'velo');
    assert(velo && velo.layoutPositioning === 'ABSOLUTE', 'dialogo sin velo: ' + marcoDialogo.name);
    assert(velo.fills[0].boundVariables.color && velo.fills[0].opacity > 0 && velo.fills[0].opacity < 1, 'velo sin color enlazado y opacidad: ' + marcoDialogo.name);
    assert(velo.children.length === 1 && velo.children[0].type === 'INSTANCE', 'el velo debe contener solo el dialogo: ' + marcoDialogo.name);
  }
  ok(`dialogos: ${dialogos.lista.length} marcos de 390x844 con velo (color enlazado con opacidad) y una instancia de dialogo (${dialogos.instancias} instancias)`);
}

const mundo = crearMundo({});
const contexto = await ejecutar(mundo);
revisar(mundo, contexto);
registrando = false;

const cantidades = () => [mundo.colecciones.length, mundo.variables.length, mundo.estilos.length, mundo.paginas.length];
const antes = cantidades();
mundo.paginas.forEach(p => {
  p.loadAsync = async () => {};
});
const contexto2 = await ejecutar(mundo);
revisar(mundo, contexto2);
assert.deepEqual(cantidades(), antes);
registrando = true;
ok('idempotencia: segunda ejecucion sin duplicar colecciones, variables, estilos ni paginas');
registrando = false;

const conAntigua = crearMundo({ conColeccionAntigua: true });
assert(conAntigua.colecciones.some(c => c.name === 'ColorScheme'));
const contexto5 = await ejecutar(conAntigua);
revisar(conAntigua, contexto5);
registrando = true;
ok('migracion: si ya existia una coleccion ColorScheme, el plugin la elimina con sus variables');
registrando = false;

const sinSemiBold = crearMundo({ sinSemiBold: true });
const contexto4 = await ejecutar(sinSemiBold);
revisar(sinSemiBold, contexto4);
registrando = true;
ok('si Roboto no tiene SemiBold, los estilos de peso 600 usan Bold');
registrando = false;

const sinGradiente = crearMundo({ sinGradiente: true });
const contexto3 = await ejecutar(sinGradiente);
revisar(sinGradiente, contexto3);
const encabezados = pagina(sinGradiente, '🧩 Componentes').children.find(c => c.name === 'EncabezadoAcceso');
assert(encabezados.children.every(c => c.fills.every(p => p.type === 'SOLID')));
registrando = true;
ok('si la API descarta el enlace del degradado, el encabezado cae a relleno solido enlazado');

console.log(reporte.map(l => '- ' + l).join('\n'));
console.log('prueba.mjs: OK (no demuestra el render en Figma real)');
