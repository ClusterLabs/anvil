import * as yup from 'yup';

import buildManifestNetworkConfigSchema from './buildManifestNetworkConfigSchema';

import {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from '../inputIds';
import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';
import buildManifestHostSchema from './buildManifestHostSchema';

const buildManifestSchema = (manifests: APIManifestOverviewList) => {
  const values = Object.values(manifests);

  const names = values.map<string>((manifest) => manifest.manifestName);

  return yup.object({
    [INPUT_ID_AI_DOMAIN]: yup.string().required(),
    [INPUT_ID_AI_PREFIX]: yup
      .string()
      .min(1)
      .max(5)
      .required()
      .test({
        exclusive: true,
        message: '${path} already exists',
        name: 'existing-name',
        test: (prefix, context) => {
          const { createError, parent } = context;

          const { [INPUT_ID_AI_SEQUENCE]: sequence } = parent;

          const paddedSequence = String(sequence).padStart(2, '0');

          const name = `${prefix}-anvil-${paddedSequence}`;

          // console.dir({
          //   prefix,
          //   sequence,
          //   paddedSequence,
          //   name,
          // });

          if (names.includes(name)) {
            return createError({
              message: `${name} already exists`,
            });
          }

          return true;
        },
      }),
    [INPUT_ID_AI_SEQUENCE]: yup.number().min(1).required(),
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
