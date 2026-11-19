import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const carpeta = process.argv[2] ?? '..';

function leer(subcarpeta) {
  const ruta = join(carpeta, subcarpeta);
  const resultado = {};
  if (!existsSync(ruta)) return resultado;
  for (const archivo of readdirSync(ruta).filter((a) => a.endsWith('.report.json'))) {
    const informe = JSON.parse(readFileSync(join(ruta, archivo), 'utf8'));
    const nombre = archivo.replace('.report.json', '');
    const auditorias = informe.audits;
    const refs = informe.categories.accessibility.auditRefs;
    const evaluadas = refs.filter((r) => auditorias[r.id].scoreDisplayMode === 'binary');
    resultado[nombre] = {
      puntaje: Math.round(informe.categories.accessibility.score * 100),
      aprobadas: evaluadas.filter((r) => auditorias[r.id].score === 1).length,
      fallidas: evaluadas.filter((r) => auditorias[r.id].score === 0).map((r) => r.id),
      manuales: refs.filter((r) => auditorias[r.id].scoreDisplayMode === 'manual').length,
      noAplican: refs.filter((r) => auditorias[r.id].scoreDisplayMode === 'notApplicable').length,
      urlFinal: informe.finalDisplayedUrl,
      version: informe.lighthouseVersion,
    };
  }
  return resultado;
}

const antes = leer('antes');
const despues = leer('despues');
const nombres = [...new Set([...Object.keys(antes), ...Object.keys(despues)])].sort();
console.log('| Ruta y formato | Antes | Aprobadas antes | Después | Aprobadas después | Fallas después |');
console.log('| --- | --- | --- | --- | --- | --- |');
for (const nombre of nombres) {
  const a = antes[nombre];
  const d = despues[nombre];
  console.log(
    `| ${nombre} | ${a?.puntaje ?? '-'} | ${a?.aprobadas ?? '-'} | ${d?.puntaje ?? '-'} | ${d?.aprobadas ?? '-'} | ${d?.fallidas.join(', ') || (d ? 'ninguna' : '-')} |`,
  );
}
console.log();
for (const nombre of nombres) {
  const a = antes[nombre];
  if (a && a.fallidas.length) console.log(`antes ${nombre}: ${a.fallidas.join(', ')}`);
}
