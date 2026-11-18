import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(join(aqui, 'tokens.json'), 'utf8'));
const plugin = readFileSync(join(aqui, 'src', 'plugin.js'), 'utf8');

const codigo = `const TOKENS = ${JSON.stringify(tokens, null, 2)};\n\n${plugin}`;
writeFileSync(join(aqui, 'code.js'), codigo);

function valorFinal(coleccion, campo) {
  const valor = tokens[coleccion][campo];
  if (typeof valor !== 'string' || valor.startsWith('#')) return valor;
  const [otra, otroCampo] = valor.split('/');
  return valorFinal(otra, otroCampo);
}

function tablaTokens() {
  const filas = ['| Token Dart | Variable Figma | Valor |', '| --- | --- | --- |'];
  for (const [coleccion, campos] of Object.entries(tokens)) {
    for (const [campo, valor] of Object.entries(campos)) {
      let mostrado;
      if (coleccion === 'TextosTruequeU') {
        mostrado = `${valorFinal('Tipos', valor.fontSize.split('/')[1])} px, peso ${valor.fontWeight}`;
      } else if (coleccion === 'ColorScheme') {
        mostrado = `${valor} (${valorFinal(coleccion, campo)})`;
      } else {
        mostrado = String(valor);
      }
      const figma = coleccion === 'TextosTruequeU' ? `Estilo de texto \`${coleccion}/${campo}\`` : `\`${coleccion}/${campo}\``;
      filas.push(`| \`${coleccion}.${campo}\` | ${figma} | ${mostrado} |`);
    }
  }
  return filas.join('\n');
}

const docs = join(aqui, '..', '..', 'docs', 'sistema-diseno.md');
if (existsSync(docs)) {
  const inicio = '<!-- tokens:inicio -->';
  const fin = '<!-- tokens:fin -->';
  const texto = readFileSync(docs, 'utf8');
  const desde = texto.indexOf(inicio);
  const hasta = texto.indexOf(fin);
  if (desde !== -1 && hasta > desde) {
    const nuevo = `${texto.slice(0, desde + inicio.length)}\n${tablaTokens()}\n${texto.slice(hasta)}`;
    writeFileSync(docs, nuevo);
  }
}

console.log('code.js generado');
