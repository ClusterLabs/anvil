import { ReactElement, useMemo } from 'react';

import AnvilHostInputGroup from './AnvilHostInputGroup';
import Grid from '../Grid';

const INPUT_ID_PREFIX_ANVIL_HOST_CONFIG = 'anvil-host-config-input';

const INPUT_GROUP_ID_PREFIX_ANVIL_HOST_CONFIG = `${INPUT_ID_PREFIX_ANVIL_HOST_CONFIG}-group`;
const INPUT_GROUP_CELL_ID_PREFIX_ANVIL_HOST_CONFIG = `${INPUT_GROUP_ID_PREFIX_ANVIL_HOST_CONFIG}-cell`;

const DEFAULT_HOST_LIST: ManifestHostList = {
  node1: {
    fences: {
      fence1: { fenceName: 'ex_pdu01', fencePort: 0 },
      fence2: { fenceName: 'ex_pdu02', fencePort: 0 },
    },
    hostNumber: 1,
    hostType: 'node',
    upses: {
      ups1: { isPowerHost: true, upsName: 'ex_ups01' },
      ups2: { isPowerHost: false, upsName: 'ex_ups02' },
    },
  },
  node2: {
    hostNumber: 2,
    hostType: 'node',
  },
  dr1: {
    hostNumber: 1,
    hostType: 'dr',
  },
};

const AnvilHostConfigInputGroup = <M extends MapToInputTestID>({
  formUtils,
  networkListEntries,
  previous: { hosts: previousHostList = DEFAULT_HOST_LIST } = {},
}: AnvilHostConfigInputGroupProps<M>): ReactElement => {
  const hostListEntries = useMemo(
    () => Object.entries(previousHostList),
    [previousHostList],
  );

  const hostNetworkList = useMemo(
    () =>
      networkListEntries.reduce<ManifestHostNetworkList>(
        (previous, [networkId, { networkNumber, networkType }]) => {
          previous[networkId] = {
            networkIp: '',
            networkNumber,
            networkType,
          };

          return previous;
        },
        {},
      ),
    [networkListEntries],
  );

  const hostListGridLayout = useMemo<GridLayout>(
    () =>
      hostListEntries.reduce<GridLayout>(
        (previous, [hostId, previousHostArgs]) => {
          const {
            hostNumber,
            hostType,
            networks = hostNetworkList,
          }: ManifestHost = previousHostArgs;

          const cellId = `${INPUT_GROUP_CELL_ID_PREFIX_ANVIL_HOST_CONFIG}-${hostId}`;

          const hostLabel = `${hostType} ${hostNumber}`;

          previous[cellId] = {
            children: (
              <AnvilHostInputGroup
                formUtils={formUtils}
                hostLabel={hostLabel}
                previous={{ ...previousHostArgs, networks }}
              />
            ),
            md: 3,
            sm: 2,
          };

          return previous;
        },
        {},
      ),
    [formUtils, hostListEntries, hostNetworkList],
  );

  return (
    <Grid
      columns={{ xs: 1, sm: 2, md: 3 }}
      layout={hostListGridLayout}
      spacing="1em"
    />
  );
};

export default AnvilHostConfigInputGroup;
