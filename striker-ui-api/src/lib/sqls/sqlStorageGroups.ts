import { DELETED } from '../consts';

export const sqlStorageGroups = () => {
  const sql = `
    SELECT *
    FROM storage_groups
    WHERE storage_group_name != '${DELETED}'`;

  return sql;
};
