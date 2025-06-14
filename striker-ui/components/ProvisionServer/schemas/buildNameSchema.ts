import * as yup from 'yup';

const buildNameSchema = <
  ServerName extends string,
  Server extends {
    name: ServerName;
    uuid: string;
  },
  ServerRecord extends Record<string, Server>,
  ServerArray extends Server[],
>(
  skip: null | string,
  servers: ServerArray | ServerRecord,
) => {
  let values: Server[];

  if (servers instanceof Array) {
    values = servers;
  } else {
    values = Object.values(servers);
  }

  if (skip) {
    values = values.filter((server) => server.uuid !== skip);
  }

  return yup
    .string()
    .min(1)
    .max(32)
    .matches(/^[\w-]+$/, {
      message:
        '${path} can only contain alphanumeric, hyphen, and underscore characters',
    })
    .notOneOf(
      values.map<string>((server) => server.name),
      '${path} already exists',
    )
    .required();
};

export default buildNameSchema;
