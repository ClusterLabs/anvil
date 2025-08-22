import { DELETED } from '../consts';

export const sqlVariables = () => {
  const sql = `
    SELECT *
    FROM variables
    WHERE variable_value != '${DELETED}'`;

  return sql;
};
