import { readFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { chromium } from 'playwright-core';

export function leerCredenciales(ruta) {
  const datos = {};
  for (const linea of readFileSync(ruta, 'utf8').split(/\r?\n/)) {
    const i = linea.indexOf('=');
    if (i > 0) datos[linea.slice(0, i)] = linea.slice(i + 1);
  }
  return datos;
}

export async function iniciarSesionEnPerfil({ base, chrome, credenciales }) {
  const perfil = mkdtempSync(join(tmpdir(), 'perfil-lh-'));
  const contexto = await chromium.launchPersistentContext(perfil, {
    executablePath: chrome,
    headless: true,
    viewport: { width: 500, height: 900 },
  });
  const pagina = await contexto.newPage();
  await pagina.goto(`${base}/#/iniciar-sesion`, { waitUntil: 'domcontentloaded', timeout: 90000 });
  await pagina.waitForSelector('flt-semantics-placeholder, flt-semantics', { state: 'attached', timeout: 60000 });
  await pagina.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await pagina.waitForSelector('flt-semantics', { state: 'attached', timeout: 20000 });
  await pagina.waitForTimeout(1500);
  const campoCorreo = pagina.getByLabel('Correo');
  const campoClave = pagina.getByLabel('Contraseña', { exact: true });
  for (let intento = 0; intento < 5; intento++) {
    await campoCorreo.fill(credenciales.correo);
    await campoClave.fill(credenciales.clave);
    if ((await campoClave.inputValue()) === credenciales.clave) break;
    await pagina.waitForTimeout(1000);
  }
  await pagina.getByRole('button', { name: 'Iniciar sesión' }).click();
  try {
    await pagina.waitForURL(/#\/feed/, { timeout: 90000 });
  } catch (error) {
    await pagina.screenshot({ path: join(tmpdir(), 'fallo-login.png') });
    await contexto.close();
    throw error;
  }
  await pagina.waitForTimeout(3000);
  await contexto.close();
  return perfil;
}
