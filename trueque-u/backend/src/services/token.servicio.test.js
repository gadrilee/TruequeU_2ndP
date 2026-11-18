jest.mock("../configuration/entorno", () => ({
  jwtSecreto: "secreto-de-prueba",
  duracionSesionDias: 7,
}));

const { firmarToken, verificarToken } = require("./token.servicio");

describe("Servicio de tokens", () => {
  test("el token firmado lleva el usuario y el id de sesion", () => {
    const token = firmarToken({ usuarioId: 5, sesionId: "sesion-1" });

    const datos = verificarToken(token);

    expect(datos.sub).toBe("5");
    expect(datos.jti).toBe("sesion-1");
  });

  test("un token alterado lanza un error", () => {
    const token = firmarToken({ usuarioId: 5, sesionId: "sesion-1" });

    expect(() => verificarToken(`${token}x`)).toThrow();
  });
});
