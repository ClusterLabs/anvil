import { formatSql } from '../formatSql';
import { access } from './instance';

export const opWrite = (sql: string) => {
  const formatted = formatSql(sql);

  return `w ${formatted}`;
};

export const write = async (...params: Parameters<typeof opWrite>) => {
  const [{ write_code: code }] = await access.default.interact<
    [
      {
        write_code: number;
      },
    ]
  >(opWrite(...params));

  return code;
};
