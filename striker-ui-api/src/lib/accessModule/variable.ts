import { sub } from './sub';

export const variable: InsertOrUpdateVariableFunction = async (params) => {
  const [uuid]: [string] = await sub('insert_or_update_variables', {
    params: [params],
  });

  return uuid;
};
