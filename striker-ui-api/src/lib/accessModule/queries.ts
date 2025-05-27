import { query } from './query';
import { perr } from '../shell';

export const queries = async (...sqls: string[]) => {
  const promises = sqls.map<Promise<QueryResult>>((sql) => query(sql));

  let results: QueryResult[];

  try {
    results = await Promise.all(promises);
  } catch (error) {
    perr(`Failed to execute sql batch; CAUSE: ${error}`);

    throw error;
  }

  return results;
};
