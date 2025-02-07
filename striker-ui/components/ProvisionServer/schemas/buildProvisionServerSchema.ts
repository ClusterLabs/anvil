import * as yup from 'yup';

import buildCpuCoresSchema from './buildCpuCoresSchema';
import buildDiskSchema from './buildDiskSchema';
import buildMemorySizeSchema from './buildMemorySizeSchema';
import buildNameSchema from './buildNameSchema';
import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';
import { yupLaxUuid } from '../../../lib/yupCommons';

const nZero = BigInt(0);

/* eslint-disable no-template-curly-in-string */

const buildProvisionServerSchema = (
  scope: ProvisionServerScope,
  resources: ProvisionServerResources,
  lsos: APIServerOses,
) => {
  // Limit the nodes to only the ones within the scope
  const nodes = scope.map<ProvisionServerResourceNode>(
    (group) => resources.nodes[group.node],
  );

  // All files are usable
  //
  // When a file is not synced to a node within the scope, the provision server
  // job will wait for the sync before continuing
  //
  // There's no need to limit the files to those already synced to nodes within
  // the scope
  // const fileUuids = Object.keys(resources.files);

  const max = nodes.reduce<{
    cpu: {
      cores: number;
    };
    memory: {
      available: bigint;
    };
  }>(
    (previous, node) => {
      const { cpu, memory } = node;

      // Find the max CPU cores of all nodes within the scope
      if (cpu.cores.total > previous.cpu.cores) {
        previous.cpu.cores = cpu.cores.total;
      }

      // Find the max available memory of all nodes within the scope
      if (memory.available > previous.memory.available) {
        previous.memory.available = memory.available;
      }

      return previous;
    },
    {
      cpu: {
        cores: 0,
      },
      memory: {
        available: nZero,
      },
    },
  );

  const osKeys = Object.keys(lsos);

  return yup.object({
    cpu: yup.object({
      cores: buildCpuCoresSchema(max.cpu.cores),
    }),
    disks: yup.lazy((disks) =>
      yup.object(
        buildYupDynamicObject(disks, buildDiskSchema(scope, resources)),
      ),
    ),
    driver: yupLaxUuid()
      .notOneOf([yup.ref('install')])
      .nullable(),
    install: yupLaxUuid()
      .notOneOf([yup.ref('driver')])
      .required(),
    memory: buildMemorySizeSchema(max.memory.available),
    name: buildNameSchema(null, resources.servers),
    node: yupLaxUuid()
      .oneOf(scope.map<string>((group) => group.node))
      .required(),
    os: yup.string().oneOf(osKeys),
  });
};

export default buildProvisionServerSchema;
