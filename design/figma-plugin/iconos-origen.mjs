export const PAQUETE = '@material-design-icons/svg';
export const VERSION = '0.14.15';
export const MARCO = ['arrow_drop_down', 'check'];

export const ALIAS = {
  info_outline: ['outlined', 'info'],
  lock_outline: ['outlined', 'lock'],
  label_outline: ['outlined', 'label'],
  bookmark_outline: ['outlined', 'bookmark'],
};

export function origen(nombre) {
  if (ALIAS[nombre]) return ALIAS[nombre];
  if (nombre.endsWith('_outlined')) return ['outlined', nombre.slice(0, -'_outlined'.length)];
  return ['filled', nombre];
}
