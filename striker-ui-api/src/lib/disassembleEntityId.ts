export const getEntityName = (id: string) => id.replace(/\d*$/, '');

export const getEntityNumber = (id: string) =>
  Number.parseInt(id.replace(/^[^\d]*/, ''));

export const getEntityParts = (id: string) => {
  let name = '';
  let number = NaN;

  const matchResult = id.match(/^([^\d]*)(\d*)$/);

  if (matchResult) {
    const parts = matchResult;

    name = parts[1];
    number = Number.parseInt(parts[2]);
  }

  return { name, number };
};
