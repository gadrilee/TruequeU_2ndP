# Reportes de pruebas y cobertura

Generados el 2026-11-18 sobre el commit `7185916` (rama `test/e2e-flow-coverage`).

## Resumen

| Capa | Pruebas | Cobertura |
|---|---|---|
| Backend (Jest) | 521 pruebas en 41 suites | Sentencias 100% (1624/1624), ramas 100% (728/728), funciones 100% (158/158), líneas 100% (1555/1555) |
| App (Flutter) | 473 pruebas | Líneas 100% (2864/2864), sin exclusiones |
| E2E (integration_test) | 159 pruebas en 12 archivos, todas aprobadas en CI | Flujos de usuario 152/152 (100%) |

La cobertura E2E se mide como cobertura de flujos de usuario, no de líneas.

## Reportes

- Backend: [backend/index.html](backend/index.html) (resumen en [backend/coverage-summary.json](backend/coverage-summary.json))
- App: [app/index.html](app/index.html)
- E2E: [e2e.md](e2e.md) y [matriz de flujos](../e2e-matriz-flujos.md)

## Regenerar

Backend, desde la raíz del repositorio:

```bash
cd trueque-u/backend
npx jest --ci --coverage --coverageReporters=html --coverageReporters=text-summary --coverageReporters=json-summary --coverageDirectory="$(cd ../../docs/reportes && pwd)/backend"
```

App, desde la raíz del repositorio (requiere Flutter y Docker; las rutas de `lcov.info` se normalizan a `/` y se hacen absolutas bajo `/app` porque en Windows usan `\`):

```bash
cd trueque-u/app
flutter test --coverage
node -e "const f=require('fs'),b=String.fromCharCode(92);f.writeFileSync('coverage/lcov.unix.info',f.readFileSync('coverage/lcov.info','utf8').split('\n').map(l=>l.startsWith('SF:')?'SF:/app/'+l.slice(3).split(b).join('/'):l).join('\n'))"
MSYS_NO_PATHCONV=1 docker run --rm -v "$(pwd -W):/app" -w /app ubuntu:24.04 bash -c "apt-get update -qq && apt-get install -y -qq lcov >/dev/null 2>&1 && genhtml coverage/lcov.unix.info -o /app/reporte_tmp --prefix /app --title 'Trueque U app' --quiet"
rm -rf ../../docs/reportes/app && mv reporte_tmp ../../docs/reportes/app
rm coverage/lcov.unix.info
```

E2E: los resultados provienen del workflow E2E de GitHub Actions. Para consultarlos:

```bash
gh run view 44383837877 -R gadrilee/TruequeU_2ndP --json jobs
```

Para ejecutar las pruebas localmente, ver `.github/workflows/e2e.yml`. El conteo de pruebas por archivo se obtiene de las declaraciones `testWidgets` en `trueque-u/app/integration_test/`.
