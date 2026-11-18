import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const aqui = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(join(aqui, 'tokens.json'), 'utf8'));
const codigo = readFileSync(join(aqui, 'code.js'), 'utf8');

const CAMPOS_NUMERICOS = [
  'width', 'height', 'itemSpacing', 'paddingLeft', 'paddingRight', 'paddingTop', 'paddingBottom',
  'topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius', 'fontSize',
];
const ALCANCES_VALIDOS = [
  'ALL_SCOPES', 'TEXT_CONTENT', 'CORNER_RADIUS', 'WIDTH_HEIGHT', 'GAP', 'ALL_FILLS', 'FRAME_FILL',
  'SHAPE_FILL', 'TEXT_FILL', 'STROKE_COLOR', 'EFFECT_COLOR', 'FONT_SIZE',
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

  class Componente extends Nodo {
    createInstance() {
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
        n.children = origen.children.map(h => copia(h, n));
        return n;
      };
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
          assert.equal(campo, 'fontSize');
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
        const c = { id: 'C' + nuevoId(), name: nombre, modes: [{ modeId: 'M' + nuevoId(), name: 'Mode 1' }] };
        mundo.colecciones.push(c);
        return c;
      },
      createVariable(nombre, coleccion, tipo) {
        assert(coleccion && coleccion.id, 'se requiere la coleccion');
        assert(['COLOR', 'FLOAT'].includes(tipo));
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
  assert.deepEqual(nombres, ['ColorScheme', 'Espacios', 'Radios', 'TemaTruequeU', 'Tipos']);
  const tipo = { TemaTruequeU: 'COLOR', ColorScheme: 'COLOR', Espacios: 'FLOAT', Radios: 'FLOAT', Tipos: 'FLOAT' };
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
      assert.equal(v.resolvedType, tipo[coleccion]);
      assert(v.scopes.length > 0);
      assert.equal(v.description, coleccion + '.' + campo);
      if (coleccion === 'ColorScheme') {
        assert.deepEqual(plano(v.valores[modo]), { type: 'VARIABLE_ALIAS', id: porRuta[valor].id });
      } else if (coleccion === 'TemaTruequeU') {
        assert.deepEqual(plano(v.valores[modo]), hexARgb(valor));
      } else {
        assert.equal(v.valores[modo], valor);
      }
      contadas++;
    }
  }
  assert.equal(mundo.variables.length, contadas);
  ok(`variables: ${contadas} (todas las claves de tokens.json, sin duplicados; ColorScheme son alias)`);

  assert.equal(mundo.estilos.length, Object.keys(tokens.TextosTruequeU).length);
  for (const e of mundo.estilos) {
    const campo = e.name.replace('TextosTruequeU/', '');
    const def = tokens.TextosTruequeU[campo];
    assert(def, 'estilo inesperado ' + e.name);
    assert.equal(e.fontName.family, 'Roboto');
    assert.equal(e.boundVariables.fontSize.id, porRuta[def.fontSize].id);
  }
  ok(`estilos de texto: ${mundo.estilos.length} con fontSize enlazado a Tipos`);

  assert.deepEqual(mundo.paginas.filter(p => p.name !== 'Page 1').map(p => p.name), ['🎨 Fundamentos', '🧩 Componentes', '📱 Pantallas']);

  const conjuntos = pagina(mundo, '🧩 Componentes').children.filter(n => n.type === 'COMPONENT_SET');
  assert(conjuntos.length >= 10);
  const esperados = [
    'LogoTruequeU', 'BotonCarga', 'CampoTexto', 'BannerError', 'ChipEstado', 'Etiqueta', 'Estrellas', 'FotoPublicacion',
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
  let solidos = 0;
  let degradados = 0;
  for (const n of todos) {
    for (const lista of [n.fills, n.strokes]) {
      for (const p of lista) {
        if (p.type === 'SOLID') {
          assert(p.boundVariables && p.boundVariables.color, `paint SOLID sin variable en ${n.type} ${n.name}`);
          solidos++;
        } else if (p.type === 'GRADIENT_LINEAR') {
          assert(p.gradientStops.every(s => s.boundVariables && s.boundVariables.color), 'degradado sin variables en ' + n.name);
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
  ok(`nodos de texto con estilo TextosTruequeU: ${textos.length}/${textos.length}`);

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
  assert.throws(() => contexto.pintura('ColorScheme/noExiste'), /Token inexistente/);
  ok('pintura() rechaza colores que no son tokens');

  const pantallas = pagina(mundo, '📱 Pantallas').children;
  assert.deepEqual(pantallas.map(p => p.name), [
    'PantallaInicio', 'PantallaIniciarSesion', 'PantallaRegistro', 'PantallaFeedPublicaciones', 'PantallaMisPublicaciones', 'PantallaPerfil',
  ]);
  let instancias = 0;
  for (const pantalla of pantallas) {
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
  ok(`pantallas: ${pantallas.length} de 390x844, solo FRAME e INSTANCE (${instancias} instancias)`);
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

const sinGradiente = crearMundo({ sinGradiente: true });
const contexto3 = await ejecutar(sinGradiente);
revisar(sinGradiente, contexto3);
const encabezados = pagina(sinGradiente, '🧩 Componentes').children.find(c => c.name === 'EncabezadoAcceso');
assert(encabezados.children.every(c => c.fills.every(p => p.type === 'SOLID')));
registrando = true;
ok('si la API descarta el enlace del degradado, el encabezado cae a relleno solido enlazado');

console.log(reporte.map(l => '- ' + l).join('\n'));
console.log('prueba.mjs: OK (no demuestra el render en Figma real)');
