import { formatSql } from '../formatSql';
import { access } from './instance';

export const query = <T extends QueryResult>(script: string) =>
  access.default.interact<T>('r', formatSql(script));
