import { formatSql } from '../formatSql';
import { access } from './instance';

export const opQuery = (sql: string) => {
  const formatted = formatSql(sql);

  return `r ${formatted}`;
};

export const query = async <T extends QueryResult>(
  ...params: Parameters<typeof opQuery>
) => {
  const [rows] = await access.default.interact<[T]>(opQuery(...params));

  return rows;
};
