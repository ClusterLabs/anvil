import { sub } from './sub';

export const insertOrUpdateUser: InsertOrUpdateUserFunction = async (
  params,
) => {
  const [uuid]: [string] = await sub('insert_or_update_users', {
    params: [params],
  });

  return uuid;
};
