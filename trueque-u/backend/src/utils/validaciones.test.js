const { esCorreoValido, esTelefonoValido, validarContrasena } = require("./validaciones");

describe("Validar correo", () => {
  test("un correo con formato correcto es valido", () => {
    expect(esCorreoValido("eudenia@correo.com")).toBe(true);
  });

  test("el correo se valida sin espacios en los bordes", () => {
    expect(esCorreoValido("  eudenia@correo.com  ")).toBe(true);
  });

  test("un correo sin arroba o dominio no es valido", () => {
    expect(esCorreoValido("eudenia.correo.com")).toBe(false);
    expect(esCorreoValido("eudenia@correo")).toBe(false);
  });

  test("un valor que no es texto no es valido", () => {
    expect(esCorreoValido(undefined)).toBe(false);
    expect(esCorreoValido(123)).toBe(false);
  });
});

describe("Validar telefono", () => {
  test("ocho digitos es valido", () => {
    expect(esTelefonoValido("71234567")).toBe(true);
    expect(esTelefonoValido(" 71234567 ")).toBe(true);
  });

  test("otra cantidad de digitos o letras no es valido", () => {
    expect(esTelefonoValido("7123456")).toBe(false);
    expect(esTelefonoValido("7123456a")).toBe(false);
  });

  test("un valor que no es texto no es valido", () => {
    expect(esTelefonoValido(71234567)).toBe(false);
    expect(esTelefonoValido(null)).toBe(false);
  });
});

describe("Validar contrasena", () => {
  test("una contrasena de seis caracteres o mas es valida", () => {
    expect(validarContrasena("abc123")).toBeNull();
  });

  test("una contrasena corta da un mensaje de error", () => {
    expect(validarContrasena("abc12")).toBe("La contraseña debe tener al menos 6 caracteres");
  });

  test("un valor que no es texto da un mensaje de error", () => {
    expect(validarContrasena(undefined)).toBe("La contraseña debe tener al menos 6 caracteres");
  });
});
