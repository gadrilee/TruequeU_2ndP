const { cifrar, coincide } = require("./contrasena.servicio");

describe("Servicio de contrasenas", () => {
  test("cifrar no deja la contrasena en texto plano", async () => {
    const hash = await cifrar("eude1234");

    expect(hash).not.toBe("eude1234");
  });

  test("coincide acepta la contrasena correcta", async () => {
    const hash = await cifrar("eude1234");

    expect(await coincide("eude1234", hash)).toBe(true);
  });

  test("coincide rechaza una contrasena distinta", async () => {
    const hash = await cifrar("eude1234");

    expect(await coincide("otra-clave", hash)).toBe(false);
  });
});
