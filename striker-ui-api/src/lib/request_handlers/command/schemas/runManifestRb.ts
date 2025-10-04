import * as yup from 'yup';

import { yupDynamicObject, yupLaxUuid } from '../../../yupCommons';

const maxHostSequence = 2;

const hostIds = Array.from(
  {
    length: maxHostSequence,
  },
  (v, i) => {
    const sequence = i + 1;

    return `node${sequence}`;
  },
);

export const runManifestHost = yup
  .object({
    id: yup.string().ensure(),
    number: yup.number().required(),
    type: yup.string().required().oneOf(['node']),
    uuid: yupLaxUuid().required(),
  })
  .transform((host) => {
    const shallow = { ...host };

    shallow.id = `${shallow.type}${shallow.number}`;

    return shallow;
  });

export const buildRunManifestRequestBodySchema = (known: {
  hosts: AnvilDataHostListHash;
  manifest: string;
  manifests: AnvilDataManifestListHash;
  sys: AnvilDataSysHash;
}) => {
  const { host_uuid: hostUuidMapToData } = known.hosts;

  const {
    manifest_uuid: {
      [known.manifest]: {
        parsed: { name: manifestName },
      },
    },
  } = known.manifests;

  const { hosts: { by_uuid: mapToHostNameData = {} } = {} } = known.sys;

  return yup
    .object({
      debug: yup.number().default(2),
      description: yup.string().ensure(),
      hosts: yup.lazy((hosts) =>
        yup.object(yupDynamicObject(hosts, runManifestHost)),
      ),
      password: yup.string().ensure(),
      rerun: yup.boolean(),
      reuseHosts: yup.boolean(),
    })
    .test({
      name: 'uniquehostid',
      test: (body, { createError }) => {
        const hosts = Object.values(body.hosts);

        const checklist = hostIds.reduce<Record<string, boolean>>(
          (previous, hostId) => {
            previous[hostId] = false;

            return previous;
          },
          {},
        );

        let last: typeof hosts[number] | undefined;

        const result = hosts.every((host) => {
          last = host;

          const { id } = host;

          // If the id is unchecked...
          if (checklist[id] === false) {
            // check it to express we've seen it,
            checklist[id] = true;
            // and continue checking.
            return true;
          }

          // If the id doesn't exists (undefined) or is already checked (true),
          // fail the test.
          return false;
        });

        if (!result && last) {
          return createError({
            message: `There can only be ${maxHostSequence} host identifiers: ${hostIds.join(
              ', ',
            )}; failed on [${last.id}]`,
          });
        }

        return true;
      },
    })
    .test({
      name: 'uniquehostuuid',
      test: (body, { createError }) => {
        const hosts = Object.values(body.hosts);

        const checklist: Record<string, boolean> = {};

        let last: typeof hosts[number] | undefined;

        const result = hosts.every((host) => {
          last = host;

          const { uuid } = host;

          // If the uuid doesn't exist on the checklist...
          if (!checklist[uuid]) {
            // add it,
            checklist[uuid] = true;
            // and continue checking.
            return true;
          }

          // If the uuid is already on the checklist, fail the test.
          return false;
        });

        if (!result && last) {
          return createError({
            message: `Host UUID must be unique; failed on [${last.uuid}] of [${last.id}]`,
          });
        }

        return true;
      },
    })
    .test({
      name: 'hostisntusedbyother',
      test: (body, { createError }) => {
        // Skip this test when we're allowed to reuse host(s).
        if (body.reuseHosts) {
          return true;
        }

        const hosts = Object.values(body.hosts);

        let last: typeof hosts[number] | undefined;

        const result = hosts.every((host) => {
          last = host;

          const { uuid } = host;

          const { anvil_name: anvilName } = hostUuidMapToData[uuid];

          // This host isn't used, continue checking.
          if (!anvilName) {
            return true;
          }

          // If the names match, it means this host is only being used by the
          // same node; the user is free to rearrange within the same node.
          //
          // If the names don't match, it means this host is being used by
          // another node, fail the test.
          return anvilName !== manifestName;
        });

        if (!result && last) {
          return createError({
            message: `Cannot use [${
              mapToHostNameData[last.uuid]
            }] for [${manifestName}] because it belongs to [${
              hostUuidMapToData[last.uuid]?.anvil_name
            }]; set reuseHost:true to allow this`,
          });
        }

        return true;
      },
    });
};
