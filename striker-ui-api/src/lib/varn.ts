export const cvar = (step: number, name: string) =>
  ['form', `config_step${step}`, name, 'value'].join('::');
