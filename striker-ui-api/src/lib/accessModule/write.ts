import { formatSql } from '../formatSql';
import { access } from './instance';

export const write = async (script: string) => {
  const { write_code: wcode } = await access.default.interact<{
    write_code: number;
  }>('w', formatSql(script));

  return wcode;
};
