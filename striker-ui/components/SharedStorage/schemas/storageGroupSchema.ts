import * as yup from 'yup';

import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';
import storageGroupMemberSchema from './storageGroupMemberSchema';

const storageGroupSchema = (
  storages: APIAnvilSharedStorageOverview,
  sgUuid: string,
) => {
  const { storageGroups: sgs } = storages;

  const { [sgUuid]: sgSelf } = sgs;

  let sgValues = Object.values(sgs);

  if (sgSelf) {
    sgValues = sgValues.filter((sg) => sg.name !== sgSelf.name);
  }

  const existingSgNames = sgValues.map<string>((sg) => sg.name);

  return yup.object({
    hosts: yup.lazy((value) =>
      yup.object(buildYupDynamicObject(value, storageGroupMemberSchema)),
    ),
    name: yup
      .string()
      .required()
      .notOneOf(existingSgNames, '${path} already exists'),
  });
};

export default storageGroupSchema;
