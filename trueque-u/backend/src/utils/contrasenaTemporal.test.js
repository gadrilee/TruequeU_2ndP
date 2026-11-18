const { generarContrasenaTemporal } = require("./contrasenaTemporal");

describe("Generar contrasena temporal", () => {
  test("tiene ocho caracteres sin letras confusas", () => {
    const contrasena = generarContrasenaTemporal();

    expect(contrasena).toHaveLength(8);
    expect(contrasena).toMatch(/^[A-HJ-NP-Za-km-z2-9]{8}$/);
  });

  test("dos contrasenas seguidas no son iguales", () => {
    expect(generarContrasenaTemporal()).not.toBe(generarContrasenaTemporal());
  });
});
