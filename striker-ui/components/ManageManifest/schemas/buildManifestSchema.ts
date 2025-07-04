import * as yup from 'yup';

import buildDuplicateTestConfig from './buildDuplicateTestConfig';
import buildManifestHostSchema from './buildManifestHostSchema';
import buildManifestNetworkConfigSchema from './buildManifestNetworkConfigSchema';
import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';
import { yupGetNotOneOf } from '../../../lib/yupCommons';

import {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from '../inputIds';

const buildManifestSchema = (manifests: APIManifestOverviewList, skip = '') => {
  let filterBy: ((manifest: APIManifestOverview) => boolean) | undefined;

  if (skip) {
    filterBy = (manifest) => manifest.manifestName !== skip;
  }

  const names = yupGetNotOneOf<APIManifestOverview>(
    manifests,
    (manifest) => manifest.manifestName,
    {
      filterBy,
    },
  );

  return yup.object({
    [INPUT_ID_AI_DOMAIN]: yup.string().required(),
    [INPUT_ID_AI_PREFIX]: yup
      .string()
      .min(1)
      .max(5)
      .required()
      .test(buildDuplicateTestConfig<string>(names)),
    [INPUT_ID_AI_SEQUENCE]: yup
      .number()
      .min(1)
      .required()
      .test(buildDuplicateTestConfig<number>(names)),
    netconf: buildManifestNetworkConfigSchema(),
    hosts: yup.lazy((obj) =>
      yup.object(buildYupDynamicObject(obj, buildManifestHostSchema())),
    ),
  });
};

type ManifestFormikValues = yup.InferType<
  ReturnType<typeof buildManifestSchema>
>;

export type { ManifestFormikValues };

export default buildManifestSchema;
