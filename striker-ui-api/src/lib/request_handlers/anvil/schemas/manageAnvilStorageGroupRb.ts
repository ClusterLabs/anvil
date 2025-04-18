import * as yup from 'yup';

import { yupLvmUuid } from '../../../yupCommons';

const lvmUuids = yup.array().of(yupLvmUuid().required()).ensure();

export const createAnvilStorageGroupRequestBodySchema = yup.object({
  add: lvmUuids,
  name: yup.string().required(),
});

export const deleteAnvilStorageGroupRequestBodySchema = yup.object({
  name: yup.string().required(),
});

export const updateAnvilStorageGroupRequestBodySchema = yup.object({
  add: lvmUuids,
  name: yup.string().required(),
  remove: lvmUuids,
  rename: yup.string(),
});
