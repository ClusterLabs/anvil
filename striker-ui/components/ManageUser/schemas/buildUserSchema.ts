import * as yup from 'yup';

import {
  INPUT_ID_USER_CONFIRM_PASSWORD,
  INPUT_ID_USER_NAME,
  INPUT_ID_USER_PASSWORD,
} from '../inputIds';

import buildUserNameSchema from './buildUserNameSchema';

const buildUserSchema = (users: APIUserOverviewList, uuid = '') => {
  const passwordSchema = yup.string();

  if (!uuid) {
    passwordSchema.required();
  }

  return yup.object({
    [INPUT_ID_USER_CONFIRM_PASSWORD]: yup
      .string()
      .when([INPUT_ID_USER_PASSWORD], (values, field) => {
        const [password] = values;

        return password ? field.required() : field;
      })
      .oneOf([yup.ref(INPUT_ID_USER_PASSWORD)]),
    [INPUT_ID_USER_NAME]: buildUserNameSchema(uuid, users).required(),
    [INPUT_ID_USER_PASSWORD]: passwordSchema,
  });
};

type UserFormikValues = yup.InferType<ReturnType<typeof buildUserSchema>>;

export type { UserFormikValues };

export default buildUserSchema;
