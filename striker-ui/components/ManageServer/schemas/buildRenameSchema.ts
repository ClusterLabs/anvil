import * as yup from 'yup';

/* eslint-disable no-template-curly-in-string */

const buildRenameSchema = (servers: APIServerOverviewList) =>
  yup.object({
    name: yup
      .string()
      .min(1)
      .max(16)
      .matches(/^[\w-]+$/, {
        message:
          '${path} can only contain alphanumeric, hyphen, and underscore characters',
      })
      .notOneOf(
        Object.values(servers).map<string>((server) => server.name),
        '${path} already exists',
      )
      .required(),
  });

export default buildRenameSchema;
