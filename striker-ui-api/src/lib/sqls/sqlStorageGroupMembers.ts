import { DELETED } from '../consts';

export const sqlStorageGroupMembers = () => {
  const sql = `
    SELECT *
    FROM storage_group_members
    WHERE storage_group_member_note != '${DELETED}'`;

  return sql;
};
