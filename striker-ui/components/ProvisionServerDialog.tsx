import { Box, Dialog, DialogProps, Grid } from '@mui/material';
import { DataSizeUnit } from 'format-data-size';
import {
  Dispatch,
  ReactNode,
  SetStateAction,
  useCallback,
  useMemo,
  useState,
} from 'react';
import { v4 as uuidv4 } from 'uuid';

import { DSIZE_SELECT_ITEMS } from '../lib/consts/DSIZES';

import api from '../lib/api';
import Autocomplete from './Autocomplete';
import ConfirmDialog from './ConfirmDialog';
import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import { dsize, dsizeToByte } from '../lib/format_data_size_wrappers';
import IconButton, { IconButtonProps } from './IconButton';
import MessageBox, { MessageBoxProps } from './MessageBox';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import OutlinedLabeledInputWithSelect from './OutlinedLabeledInputWithSelect';
import { Panel, PanelHeader } from './Panels';
import SelectWithLabel from './SelectWithLabel';
import Spinner from './Spinner';
import SyncIndicator from './SyncIndicator';
import {
  testInput as baseTestInput,
  testMax,
  testNotBlank,
  testRange,
} from '../lib/test_input';
import { BodyText, HeaderText, InlineMonoText } from './Text';
import useFetch from '../hooks/useFetch';

type InputMessage = Partial<Pick<MessageBoxProps, 'type' | 'text'>>;

type ProvisionServerDialogProps = {
  dialogProps: DialogProps;
  onClose: IconButtonProps['onClick'];
};

type HostMetadataForProvisionServerHost = {
  hostUUID: string;
  hostName: string;
  hostCPUCores: number;
  hostMemory: string;
};

type ServerMetadataForProvisionServer = {
  serverUUID: string;
  serverName: string;
  serverCPUCores: number;
  serverMemory: string;
};

type StorageGroupMetadataForProvisionServer = {
  storageGroupUUID: string;
  storageGroupName: string;
  storageGroupSize: string;
  storageGroupFree: string;
};

type FileMetadataForProvisionServer = {
  fileUUID: string;
  fileName: string;
};

type OrganizedServerMetadataForProvisionServer = Omit<
  ServerMetadataForProvisionServer,
  'serverMemory'
> & {
  serverMemory: bigint;
};

type OrganizedStorageGroupMetadataForProvisionServer = Omit<
  StorageGroupMetadataForProvisionServer,
  'storageGroupSize' | 'storageGroupFree'
> & {
  anvilUUID: string;
  anvilName: string;
  storageGroupSize: bigint;
  storageGroupFree: bigint;
};

type AnvilDetailMetadataForProvisionServer = {
  anvilUUID: string;
  anvilName: string;
  anvilDescription?: string;
  anvilTotalCPUCores: number;
  anvilTotalMemory: string;
  anvilTotalAllocatedCPUCores: number;
  anvilTotalAllocatedMemory: string;
  anvilTotalAvailableCPUCores: number;
  anvilTotalAvailableMemory: string;
  hosts: Array<HostMetadataForProvisionServerHost>;
  servers: Array<ServerMetadataForProvisionServer>;
  storageGroups: Array<StorageGroupMetadataForProvisionServer>;
  files: Array<FileMetadataForProvisionServer>;
};

type AnvilDetailForProvisionServer = {
  anvils: AnvilDetailMetadataForProvisionServer[];
  oses: Record<string, string>;
};

type OrganizedAnvilDetailMetadataForProvisionServer = Omit<
  AnvilDetailMetadataForProvisionServer,
  | 'anvilTotalMemory'
  | 'anvilTotalAllocatedMemory'
  | 'anvilTotalAvailableMemory'
  | 'hosts'
  | 'servers'
  | 'storageGroups'
> & {
  anvilTotalMemory: bigint;
  anvilTotalAllocatedMemory: bigint;
  anvilTotalAvailableMemory: bigint;
  hosts: Array<
    Omit<HostMetadataForProvisionServerHost, 'hostMemory'> & {
      hostMemory: bigint;
    }
  >;
  servers: Array<OrganizedServerMetadataForProvisionServer>;
  storageGroupUUIDs: string[];
  storageGroups: Array<OrganizedStorageGroupMetadataForProvisionServer>;
  fileUUIDs: string[];
};

type AnvilUUIDMapToData = {
  [uuid: string]: OrganizedAnvilDetailMetadataForProvisionServer;
};

type FileUUIDMapToData = {
  [uuid: string]: FileMetadataForProvisionServer;
};

type ServerNameMapToData = {
  [name: string]: OrganizedServerMetadataForProvisionServer;
};

type StorageGroupUUIDMapToData = {
  [uuid: string]: OrganizedStorageGroupMetadataForProvisionServer;
};

type OSAutoCompleteOption = { label: string; key: string };

type FilterAnvilsFunction = (
  allAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  storageGroupUUIDMapToData: StorageGroupUUIDMapToData,
  cpuCores: number,
  memory: bigint,
  vdSizes: bigint[],
  storageGroupUUIDs: string[],
  fileUUIDs: string[],
  options?: {
    includeAnvilUUIDs?: string[];
    includeFileUUIDs?: string[];
    includeStorageGroupUUIDs?: string[];
  },
) => {
  anvils: OrganizedAnvilDetailMetadataForProvisionServer[];
  anvilUUIDs: string[];
  fileUUIDs: string[];
  maxCPUCores: number;
  maxMemory: bigint;
  maxVirtualDiskSizes: bigint[];
  storageGroupUUIDs: string[];
};

type VirtualDiskStates = {
  stateIds: string[];
  inputMaxes: string[];
  inputSizeMessages: Array<InputMessage | undefined>;
  inputSizes: string[];
  inputStorageGroupUUIDMessages: Array<InputMessage | undefined>;
  inputStorageGroupUUIDs: string[];
  inputUnits: DataSizeUnit[];
  maxes: bigint[];
  sizes: bigint[];
};

type UpdateLimitsFunction = (options?: {
  allAnvils?: OrganizedAnvilDetailMetadataForProvisionServer[];
  cpuCores?: number;
  fileUUIDs?: string[];
  includeAnvilUUIDs?: string[];
  includeFileUUIDs?: string[];
  includeStorageGroupUUIDs?: string[];
  inputMemoryUnit?: DataSizeUnit;
  memory?: bigint;
  storageGroupUUIDMapToData?: StorageGroupUUIDMapToData;
  virtualDisks?: VirtualDiskStates;
}) => Pick<
  ReturnType<FilterAnvilsFunction>,
  'maxCPUCores' | 'maxMemory' | 'maxVirtualDiskSizes'
> & {
  formattedMaxMemory: string;
  formattedMaxVDSizes: string[];
};

type ProvisionServerStructures = {
  anvils: OrganizedAnvilDetailMetadataForProvisionServer[];
  anvilSelectItems: SelectItem[];
  anvilUUIDMapToData: AnvilUUIDMapToData;
  files: FileMetadataForProvisionServer[];
  fileSelectItems: SelectItem[];
  fileUUIDMapToData: FileUUIDMapToData;
  osAutocompleteOptions: OSAutoCompleteOption[];
  serverNameMapToData: ServerNameMapToData;
  storageGroups: OrganizedStorageGroupMetadataForProvisionServer[];
  storageGroupSelectItems: SelectItem[];
  storageGroupUUIDMapToData: StorageGroupUUIDMapToData;
};

const BIGINT_ZERO = BigInt(0);

const INITIAL_DATA_SIZE_UNIT: DataSizeUnit = 'GiB';

const CPU_CORES_MIN = 1;
// Unit: bytes; 64 KiB
const MEMORY_MIN = BigInt(65536);
// Unit: bytes; 100 MiB
const VIRTUAL_DISK_SIZE_MIN = BigInt(104857600);

const createMaxValueButton = (
  maxValue: string,
  {
    onButtonClick,
  }: {
    onButtonClick?: ContainedButtonProps['onClick'];
  },
) => (
  <ContainedButton
    disabled={onButtonClick === undefined}
    onClick={onButtonClick}
    sx={{
      minWidth: 'unset',
      whiteSpace: 'nowrap',
    }}
  >{`Max: ${maxValue}`}</ContainedButton>
);

const createSelectItemDisplay = ({
  endAdornment,
  mainLabel,
  subLabel,
}: {
  endAdornment?: ReactNode;
  mainLabel?: string;
  subLabel?: string;
} = {}) => (
  <Box
    sx={{
      alignItems: 'center',
      display: 'flex',
      flexDirection: 'row',
      width: '100%',

      '& > :first-child': { flexGrow: 1 },
    }}
  >
    <Box sx={{ display: 'flex', flexDirection: 'column' }}>
      {mainLabel && <BodyText inverted text={mainLabel} />}
      {subLabel && <BodyText inverted text={subLabel} />}
    </Box>
    {endAdornment}
  </Box>
);

const organizeAnvils = (data: AnvilDetailMetadataForProvisionServer[]) => {
  const allFiles: Record<string, FileMetadataForProvisionServer> = {};

  const result = data.reduce<{
    anvils: OrganizedAnvilDetailMetadataForProvisionServer[];
    anvilSelectItems: SelectItem[];
    anvilUUIDMapToData: AnvilUUIDMapToData;
    files: FileMetadataForProvisionServer[];
    fileSelectItems: SelectItem[];
    fileUUIDMapToData: FileUUIDMapToData;
    serverNameMapToData: ServerNameMapToData;
    storageGroups: OrganizedStorageGroupMetadataForProvisionServer[];
    storageGroupSelectItems: SelectItem[];
    storageGroupUUIDMapToData: StorageGroupUUIDMapToData;
  }>(
    (reduceContainer, anvil) => {
      const {
        anvilUUID,
        anvilName,
        anvilTotalMemory,
        anvilTotalAllocatedMemory,
        anvilTotalAvailableMemory,
        hosts,
        servers,
        storageGroups,
        files,
      } = anvil;

      const { anvilStorageGroups, anvilStorageGroupUUIDs } =
        storageGroups.reduce<{
          anvilStorageGroups: OrganizedStorageGroupMetadataForProvisionServer[];
          anvilStorageGroupUUIDs: string[];
        }>(
          (reducedStorageGroups, storageGroup) => {
            const resultStorageGroup = {
              ...storageGroup,
              anvilUUID,
              anvilName,
              storageGroupSize: BigInt(storageGroup.storageGroupSize),
              storageGroupFree: BigInt(storageGroup.storageGroupFree),
              humanizedStorageGroupFree: '',
            };

            dsize(storageGroup.storageGroupFree, {
              fromUnit: 'B',
              onSuccess: {
                string: (value, unit) => {
                  resultStorageGroup.humanizedStorageGroupFree = `${value} ${unit}`;
                },
              },
              precision: 0,
              toUnit: 'ibyte',
            });

            reducedStorageGroups.anvilStorageGroupUUIDs.push(
              storageGroup.storageGroupUUID,
            );
            reducedStorageGroups.anvilStorageGroups.push(resultStorageGroup);

            reduceContainer.storageGroups.push(resultStorageGroup);
            reduceContainer.storageGroupSelectItems.push({
              displayValue: createSelectItemDisplay({
                endAdornment: (
                  <BodyText
                    inverted
                    text={`~${resultStorageGroup.humanizedStorageGroupFree} free`}
                  />
                ),
                mainLabel: storageGroup.storageGroupName,
                subLabel: anvilName,
              }),
              value: storageGroup.storageGroupUUID,
            });
            reduceContainer.storageGroupUUIDMapToData[
              storageGroup.storageGroupUUID
            ] = resultStorageGroup;

            return reducedStorageGroups;
          },
          {
            anvilStorageGroups: [],
            anvilStorageGroupUUIDs: [],
          },
        );

      const fileUUIDs: string[] = [];

      files.forEach((file) => {
        const { fileUUID } = file;

        fileUUIDs.push(fileUUID);

        allFiles[fileUUID] = file;
      });

      const resultAnvil = {
        ...anvil,
        anvilTotalMemory: BigInt(anvilTotalMemory),
        anvilTotalAllocatedMemory: BigInt(anvilTotalAllocatedMemory),
        anvilTotalAvailableMemory: BigInt(anvilTotalAvailableMemory),
        humanizedAnvilTotalAvailableMemory: '',
        hosts: hosts.map((host) => ({
          ...host,
          hostMemory: BigInt(host.hostMemory),
        })),
        servers: servers.map(({ serverMemory, serverName, ...serverRest }) => {
          const resultServer = {
            ...serverRest,
            serverMemory: BigInt(serverMemory),
            serverName,
          };

          reduceContainer.serverNameMapToData[serverName] = resultServer;

          return resultServer;
        }),
        storageGroupUUIDs: anvilStorageGroupUUIDs,
        storageGroups: anvilStorageGroups,
        fileUUIDs,
      };

      dsize(anvilTotalAvailableMemory, {
        fromUnit: 'B',
        onSuccess: {
          string: (value, unit) => {
            resultAnvil.humanizedAnvilTotalAvailableMemory = `${value} ${unit}`;
          },
        },
        precision: 0,
        toUnit: 'ibyte',
      });

      reduceContainer.anvils.push(resultAnvil);
      reduceContainer.anvilSelectItems.push({
        displayValue: createSelectItemDisplay({
          endAdornment: (
            <Box
              sx={{ display: 'flex', flexDirection: 'column', width: '8rem' }}
            >
              <BodyText
                inverted
                text={`CPU: ${resultAnvil.anvilTotalCPUCores} cores`}
              />
              <BodyText
                inverted
                text={`Memory: ~${resultAnvil.humanizedAnvilTotalAvailableMemory}`}
              />
            </Box>
          ),
          mainLabel: resultAnvil.anvilName,
          subLabel: resultAnvil.anvilDescription,
        }),
        value: anvilUUID,
      });
      reduceContainer.anvilUUIDMapToData[anvilUUID] = resultAnvil;

      return reduceContainer;
    },
    {
      anvils: [],
      anvilSelectItems: [],
      anvilUUIDMapToData: {},
      files: [],
      fileSelectItems: [],
      fileUUIDMapToData: {},
      serverNameMapToData: {},
      storageGroups: [],
      storageGroupSelectItems: [],
      storageGroupUUIDMapToData: {},
    },
  );

  Object.values(allFiles).forEach((distinctFile) => {
    result.files.push(distinctFile);
    result.fileSelectItems.push({
      displayValue: distinctFile.fileName,
      value: distinctFile.fileUUID,
    });
    result.fileUUIDMapToData[distinctFile.fileUUID] = distinctFile;
  });

  return result;
};

const filterAnvils: FilterAnvilsFunction = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  storageGroupUUIDMapToData: StorageGroupUUIDMapToData,
  cpuCores: number,
  memory: bigint,
  vdSizes: bigint[],
  storageGroupUUIDs: string[],
  fileUUIDs: string[],
  {
    includeAnvilUUIDs = [],
    includeFileUUIDs = [],
    includeStorageGroupUUIDs = [],
  } = {},
) => {
  let testIncludeAnvil: (uuid: string) => boolean = () => true;
  let testIncludeFile: (uuid: string) => boolean = () => true;
  let testIncludeStorageGroup: (uuid: string) => boolean = () => true;

  if (includeAnvilUUIDs.length > 0) {
    testIncludeAnvil = (uuid: string) => includeAnvilUUIDs.includes(uuid);
  }

  if (includeFileUUIDs.length > 0) {
    testIncludeFile = (uuid: string) => includeFileUUIDs.includes(uuid);
  }

  if (includeStorageGroupUUIDs.length > 0) {
    testIncludeStorageGroup = (uuid: string) =>
      includeStorageGroupUUIDs.includes(uuid);
  }

  const resultFileUUIDs: Record<string, boolean> = {};

  const storageGroupTotals = storageGroupUUIDs.reduce<{
    all: bigint;
    [uuid: string]: bigint;
  }>(
    (totals, uuid, index) => {
      const vdSize: bigint = vdSizes[index] ?? BIGINT_ZERO;

      totals.all += vdSize;

      if (uuid === '') {
        return totals;
      }

      if (totals[uuid] === undefined) {
        totals[uuid] = BIGINT_ZERO;
      }

      totals[uuid] += vdSize;

      return totals;
    },
    { all: BIGINT_ZERO },
  );

  const result = organizedAnvils.reduce<{
    anvils: OrganizedAnvilDetailMetadataForProvisionServer[];
    anvilUUIDs: string[];
    fileUUIDs: string[];
    maxCPUCores: number;
    maxMemory: bigint;
    maxVirtualDiskSizes: bigint[];
    storageGroupUUIDs: string[];
  }>(
    (reduceContainer, organizedAnvil) => {
      const { anvilUUID } = organizedAnvil;

      if (testIncludeAnvil(anvilUUID)) {
        const {
          anvilTotalCPUCores,
          anvilTotalAvailableMemory,
          files,
          fileUUIDs: anvilFileUUIDs,
          storageGroups,
        } = organizedAnvil;

        const anvilStorageGroupUUIDs: string[] = [];
        let anvilStorageGroupFreeMax: bigint = BIGINT_ZERO;
        let anvilStorageGroupFreeTotal: bigint = BIGINT_ZERO;

        // Summarize storage groups in this anvil node to produce all UUIDs, max
        // free space, and total free space.
        storageGroups.forEach(({ storageGroupUUID, storageGroupFree }) => {
          if (testIncludeStorageGroup(storageGroupUUID)) {
            anvilStorageGroupUUIDs.push(storageGroupUUID);
            anvilStorageGroupFreeTotal += storageGroupFree;

            if (storageGroupFree > anvilStorageGroupFreeMax) {
              anvilStorageGroupFreeMax = storageGroupFree;
            }
          }
        });

        const usableTests: (() => boolean)[] = [
          // Does this anvil node have at least one storage group?
          () => storageGroups.length > 0,
          // Does this anvil node have enough CPU cores?
          () => cpuCores <= anvilTotalCPUCores,
          // Does this anvil node have enough memory?
          () => memory <= anvilTotalAvailableMemory,
          // For every virtual disk:
          // 1. Does this anvil node have the selected storage group which
          //    will contain the VD?
          // 2. Does the selected storage group OR any storage group on this
          //    anvil node have enough free space?
          () =>
            storageGroupUUIDs.every((uuid, index) => {
              const vdSize = vdSizes[index] ?? BIGINT_ZERO;
              let hasStorageGroup = true;
              let hasEnoughStorage = vdSize <= anvilStorageGroupFreeMax;

              if (uuid !== '') {
                hasStorageGroup = anvilStorageGroupUUIDs.includes(uuid);
                hasEnoughStorage =
                  vdSize <= storageGroupUUIDMapToData[uuid].storageGroupFree;
              }

              return hasStorageGroup && hasEnoughStorage;
            }),
          // Do storage groups on this anvil node have enough free space to
          // contain multiple VDs?
          () =>
            Object.entries(storageGroupTotals).every(([uuid, total]) =>
              uuid === 'all'
                ? total <= anvilStorageGroupFreeTotal
                : total <= storageGroupUUIDMapToData[uuid].storageGroupFree,
            ),
          // Does this anvil node have access to selected files?
          () =>
            fileUUIDs.every(
              (fileUUID) =>
                fileUUID === '' || anvilFileUUIDs.includes(fileUUID),
            ),
        ];

        // If an anvil doesn't pass all tests, then it and its parts shouldn't be used.
        if (usableTests.every((test) => test())) {
          reduceContainer.anvils.push(organizedAnvil);
          reduceContainer.anvilUUIDs.push(anvilUUID);

          reduceContainer.maxCPUCores = Math.max(
            anvilTotalCPUCores,
            reduceContainer.maxCPUCores,
          );

          if (anvilTotalAvailableMemory > reduceContainer.maxMemory) {
            reduceContainer.maxMemory = anvilTotalAvailableMemory;
          }

          files.forEach(({ fileUUID }) => {
            if (testIncludeFile(fileUUID)) {
              resultFileUUIDs[fileUUID] = true;
            }
          });

          reduceContainer.storageGroupUUIDs.push(...anvilStorageGroupUUIDs);
          reduceContainer.maxVirtualDiskSizes.fill(anvilStorageGroupFreeMax);
        }
      }

      return reduceContainer;
    },
    {
      anvils: [],
      anvilUUIDs: [],
      fileUUIDs: [],
      maxCPUCores: 0,
      maxMemory: BIGINT_ZERO,
      maxVirtualDiskSizes: storageGroupUUIDs.map(() => BIGINT_ZERO),
      storageGroupUUIDs: [],
    },
  );

  result.fileUUIDs = Object.keys(resultFileUUIDs);

  storageGroupUUIDs.forEach((uuid: string, uuidIndex: number) => {
    if (uuid !== '') {
      result.maxVirtualDiskSizes[uuidIndex] =
        storageGroupUUIDMapToData[uuid].storageGroupFree;
    }
  });

  return result;
};

const createVirtualDiskForm = (
  virtualDisks: VirtualDiskStates,
  vdIndex: number,
  setVirtualDisks: Dispatch<SetStateAction<VirtualDiskStates>>,
  storageGroupSelectItems: SelectItem[],
  includeStorageGroupUUIDs: string[],
  updateLimits: UpdateLimitsFunction,
  storageGroupUUIDMapToData: StorageGroupUUIDMapToData,
  testInput: TestInputFunction,
) => {
  const get = <Key extends keyof VirtualDiskStates>(
    key: Key,
    gIndex: number = vdIndex,
  ) => virtualDisks[key][gIndex] as VirtualDiskStates[Key][number];

  const set = <Key extends keyof VirtualDiskStates>(
    key: Key,
    value: VirtualDiskStates[Key][number],
    sIndex: number = vdIndex,
  ) => {
    virtualDisks[key][sIndex] = value;
    setVirtualDisks({ ...virtualDisks });
  };

  const changeVDSize = (cvsValue: bigint = BIGINT_ZERO) => {
    set('sizes', cvsValue);

    const { formattedMaxVDSizes, maxVirtualDiskSizes } = updateLimits({
      virtualDisks,
    });

    testInput({
      inputs: {
        [`vd${vdIndex}Size`]: {
          displayMax: `${formattedMaxVDSizes[vdIndex]}`,
          max: maxVirtualDiskSizes[vdIndex],
          value: cvsValue,
        },
      },
    });
  };

  const handleVDSizeChange = ({
    value = get('inputSizes'),
    unit = get('inputUnits'),
  }: {
    value?: string;
    unit?: DataSizeUnit;
  }) => {
    if (value !== get('inputSizes')) {
      set('inputSizes', value);
    }

    if (unit !== get('inputUnits')) {
      set('inputUnits', unit);
    }

    dsizeToByte(
      value,
      unit,
      (convertedVDSize) => changeVDSize(convertedVDSize),
      () => changeVDSize(),
    );
  };

  const handleVDStorageGroupChange = (uuid = get('inputStorageGroupUUIDs')) => {
    if (uuid !== get('inputStorageGroupUUIDs')) {
      set('inputStorageGroupUUIDs', uuid);
    }

    updateLimits({ virtualDisks });
  };

  return (
    <Box
      key={`ps-virtual-disk-${get('stateIds')}`}
      sx={{
        display: 'flex',
        flexDirection: 'column',

        '& > :not(:first-child)': {
          marginTop: '1em',
        },
      }}
    >
      <OutlinedLabeledInputWithSelect
        id={`ps-virtual-disk-size-${vdIndex}`}
        label="Disk size"
        messageBoxProps={get('inputSizeMessages')}
        inputWithLabelProps={{
          inputProps: {
            endAdornment: createMaxValueButton(
              `${get('inputMaxes')} ${get('inputUnits')}`,
              {
                onButtonClick: () => {
                  set('inputSizes', get('inputMaxes'));
                  changeVDSize(get('maxes'));
                },
              },
            ),
            onChange: ({ target: { value } }) => {
              handleVDSizeChange({ value });
            },
            type: 'number',
            value: get('inputSizes'),
          },
          inputLabelProps: {
            isNotifyRequired: get('sizes') === BIGINT_ZERO,
          },
        }}
        selectItems={DSIZE_SELECT_ITEMS}
        selectWithLabelProps={{
          selectProps: {
            onChange: ({ target: { value } }) => {
              const selectedUnit = value as DataSizeUnit;

              handleVDSizeChange({ unit: selectedUnit });
            },
            value: get('inputUnits'),
          },
        }}
      />
      <SelectWithLabel
        id={`ps-storage-group-${vdIndex}`}
        label="Storage group"
        disableItem={(value) =>
          !(
            includeStorageGroupUUIDs.includes(value) &&
            get('sizes') <= storageGroupUUIDMapToData[value].storageGroupFree
          )
        }
        inputLabelProps={{
          isNotifyRequired: get('inputStorageGroupUUIDs').length === 0,
        }}
        messageBoxProps={get('inputStorageGroupUUIDMessages')}
        selectItems={storageGroupSelectItems}
        selectProps={{
          onChange: ({ target: { value } }) => {
            const selectedStorageGroupUUID = value as string;

            handleVDStorageGroupChange(selectedStorageGroupUUID);
          },
          onClearIndicatorClick: () => handleVDStorageGroupChange(''),
          renderValue: (value) => {
            const {
              anvilName: rvAnvilName = '?',
              storageGroupName: rvStorageGroupName = `Unknown (${value})`,
            } = storageGroupUUIDMapToData[value as string] ?? {};

            return `${rvStorageGroupName} (${rvAnvilName})`;
          },
          value: get('inputStorageGroupUUIDs'),
        }}
      />
    </Box>
  );
};

const addVirtualDisk = ({
  existingVirtualDisks: virtualDisks = {
    stateIds: [],
    inputMaxes: [],
    inputSizeMessages: [],
    inputSizes: [],
    inputStorageGroupUUIDMessages: [],
    inputStorageGroupUUIDs: [],
    inputUnits: [],
    maxes: [],
    sizes: [],
  },
  stateId = uuidv4(),
  inputMax = '0',
  inputSize = '',
  inputSizeMessage = undefined,
  inputStorageGroupUUID = '',
  inputStorageGroupUUIDMessage = undefined,
  inputUnit = INITIAL_DATA_SIZE_UNIT,
  max = BIGINT_ZERO,
  setVirtualDisks,
  size = BIGINT_ZERO,
}: {
  existingVirtualDisks?: VirtualDiskStates;
  stateId?: string;
  inputMax?: string;
  inputSize?: string;
  inputSizeMessage?: InputMessage | undefined;
  inputStorageGroupUUID?: string;
  inputStorageGroupUUIDMessage?: InputMessage | undefined;
  inputUnit?: DataSizeUnit;
  max?: bigint;
  setVirtualDisks?: Dispatch<SetStateAction<VirtualDiskStates>>;
  size?: bigint;
} = {}) => {
  const {
    stateIds,
    inputMaxes,
    inputSizeMessages,
    inputSizes,
    inputStorageGroupUUIDMessages,
    inputStorageGroupUUIDs,
    inputUnits,
    maxes,
    sizes,
  } = virtualDisks;

  stateIds.push(stateId);
  inputMaxes.push(inputMax);
  inputSizeMessages.push(inputSizeMessage);
  inputSizes.push(inputSize);
  inputStorageGroupUUIDMessages.push(inputStorageGroupUUIDMessage);
  inputStorageGroupUUIDs.push(inputStorageGroupUUID);
  inputUnits.push(inputUnit);
  maxes.push(max);
  sizes.push(size);

  setVirtualDisks?.call(null, { ...virtualDisks });

  return virtualDisks;
};

const filterBlanks: (array: string[]) => string[] = (array: string[]) =>
  array.filter((value) => value !== '');

const getDisplayDsizeOptions = (
  onSuccessString: (value: string, unit: DataSizeUnit) => void,
): Parameters<typeof dsize>[1] => ({
  fromUnit: 'B',
  onSuccess: {
    string: onSuccessString,
  },
  precision: 0,
  toUnit: 'ibyte',
});

let displayMemoryMin: string;
let displayVirtualDiskSizeMin: string;

dsize(
  MEMORY_MIN,
  getDisplayDsizeOptions((value, unit) => {
    displayMemoryMin = `${value} ${unit}`;
  }),
);

dsize(
  VIRTUAL_DISK_SIZE_MIN,
  getDisplayDsizeOptions((value, unit) => {
    displayVirtualDiskSizeMin = `${value} ${unit}`;
  }),
);

const ProvisionServerDialog = ({
  dialogProps: { open },
  onClose: onCloseProvisionServerDialog,
}: ProvisionServerDialogProps): JSX.Element => {
  const [allAnvils, setAllAnvils] = useState<
    OrganizedAnvilDetailMetadataForProvisionServer[]
  >([]);
  // Provision is impossible when one of anvil node list, file list, or storage
  // group list is empty.
  const [anvilUUIDMapToData, setAnvilUUIDMapToData] =
    useState<AnvilUUIDMapToData>({});
  const [fileUUIDMapToData, setFileUUIDMapToData] = useState<FileUUIDMapToData>(
    {},
  );
  const [serverNameMapToData, setServerNameMapToData] =
    useState<ServerNameMapToData>({});
  const [storageGroupUUIDMapToData, setStorageGroupUUIDMapToData] =
    useState<StorageGroupUUIDMapToData>({});

  const [anvilSelectItems, setAnvilSelectItems] = useState<SelectItem[]>([]);
  const [fileSelectItems, setFileSelectItems] = useState<SelectItem[]>([]);
  const [osAutocompleteOptions, setOSAutocompleteOptions] = useState<
    OSAutoCompleteOption[]
  >([]);
  const [storageGroupSelectItems, setStorageGroupSelectItems] = useState<
    SelectItem[]
  >([]);

  const [inputServerNameValue, setInputServerNameValue] = useState<string>('');
  const [inputServerNameMessage, setInputServerNameMessage] = useState<
    InputMessage | undefined
  >();

  const [inputCPUCoresValue, setInputCPUCoresValue] = useState<number>(1);
  const [inputCPUCoresMax, setInputCPUCoresMax] = useState<number>(0);
  const [inputCPUCoresMessage, setInputCPUCoresMessage] = useState<
    InputMessage | undefined
  >();

  const [memory, setMemory] = useState<bigint>(BIGINT_ZERO);
  const [memoryMax, setMemoryMax] = useState<bigint>(BIGINT_ZERO);
  const [inputMemoryMessage, setInputMemoryMessage] = useState<
    InputMessage | undefined
  >();
  const [inputMemoryMax, setInputMemoryMax] = useState<string>('0');
  const [inputMemoryValue, setInputMemoryValue] = useState<string>('');
  const [inputMemoryUnit, setInputMemoryUnit] = useState<DataSizeUnit>(
    INITIAL_DATA_SIZE_UNIT,
  );

  const [virtualDisks, setVirtualDisks] = useState<VirtualDiskStates>(
    addVirtualDisk(),
  );

  const [inputInstallISOFileUUID, setInputInstallISOFileUUID] =
    useState<string>('');
  const [inputInstallISOMessage, setInputInstallISOMessage] = useState<
    InputMessage | undefined
  >();
  const [inputDriverISOFileUUID, setInputDriverISOFileUUID] =
    useState<string>('');
  const [inputDriverISOMessage] = useState<InputMessage | undefined>();

  const [inputAnvilValue, setInputAnvilValue] = useState<string>('');
  const [inputAnvilMessage, setInputAnvilMessage] = useState<
    InputMessage | undefined
  >();

  const [inputOptimizeForOSValue, setInputOptimizeForOSValue] =
    useState<OSAutoCompleteOption | null>(null);
  const [inputOptimizeForOSMessage, setInputOptimizeForOSMessage] = useState<
    InputMessage | undefined
  >();

  const [includeAnvilUUIDs, setIncludeAnvilUUIDs] = useState<string[]>([]);
  const [includeFileUUIDs, setIncludeFileUUIDs] = useState<string[]>([]);
  const [includeStorageGroupUUIDs, setIncludeStorageGroupUUIDs] = useState<
    string[]
  >([]);

  const [isProvisionServerDataReady, setIsProvisionServerDataReady] =
    useState<boolean>(false);
  const [isOpenProvisionConfirmDialog, setIsOpenProvisionConfirmDialog] =
    useState<boolean>(false);
  const [isProvisionRequestInProgress, setIsProvisionRequestInProgress] =
    useState<boolean>(false);

  const [successfulProvisionCount, setSuccessfulProvisionCount] =
    useState<number>(0);

  const inputCpuCoresOptions = useMemo(() => {
    const result: number[] = [];

    for (let i = CPU_CORES_MIN; i <= inputCPUCoresMax; i += 1) {
      result.push(i);
    }

    return result;
  }, [inputCPUCoresMax]);

  const inputTests: InputTestBatches = {
    serverName: {
      defaults: {
        onSuccess: () => {
          setInputServerNameMessage(undefined);
        },
        value: inputServerNameValue,
      },
      isRequired: true,
      tests: [
        {
          onFailure: () => {
            setInputServerNameMessage({
              text: 'The server name length must be 1 to 16 characters.',
              type: 'warning',
            });
          },
          test: ({ value }) => {
            const { length } = value as string;

            return length >= 1 && length <= 16;
          },
        },
        {
          onFailure: () => {
            setInputServerNameMessage({
              text: 'The server name is expected to only contain alphanumeric, hyphen, or underscore characters.',
              type: 'warning',
            });
          },
          test: ({ value }) => /^[a-zA-Z0-9_-]+$/.test(value as string),
        },
        {
          onFailure: () => {
            setInputServerNameMessage({
              text: `This server name already exists, please choose another name.`,
              type: 'warning',
            });
          },
          test: ({ value }) =>
            serverNameMapToData[value as string] === undefined,
        },
      ],
    },
    cpuCores: {
      defaults: {
        max: inputCPUCoresMax,
        min: CPU_CORES_MIN,
        onSuccess: () => {
          setInputCPUCoresMessage(undefined);
        },
        value: inputCPUCoresValue,
      },
      isRequired: true,
      tests: [
        {
          onFailure: () => {
            setInputCPUCoresMessage({
              text: 'Non available.',
              type: 'warning',
            });
          },
          test: testMax,
        },
        {
          onFailure: ({ displayMax, displayMin }) => {
            setInputCPUCoresMessage({
              text: `The number of CPU cores is expected to be between ${displayMin} and ${displayMax}.`,
              type: 'warning',
            });
          },
          test: testRange,
        },
      ],
    },
    memory: {
      defaults: {
        displayMax: `${inputMemoryMax} ${inputMemoryUnit}`,
        displayMin: displayMemoryMin,
        max: memoryMax,
        min: MEMORY_MIN,
        onSuccess: () => {
          setInputMemoryMessage(undefined);
        },
        value: memory,
      },
      isRequired: true,
      tests: [
        {
          onFailure: () => {
            setInputMemoryMessage({ text: 'Non available.', type: 'warning' });
          },
          test: testMax,
        },
        {
          onFailure: ({ displayMax, displayMin }) => {
            setInputMemoryMessage({
              text: `Memory is expected to be between ${displayMin} and ${displayMax}.`,
              type: 'warning',
            });
          },
          test: testRange,
        },
      ],
    },
    installISO: {
      defaults: {
        onSuccess: () => {
          setInputInstallISOMessage(undefined);
        },
        value: inputInstallISOFileUUID,
      },
      isRequired: true,
      tests: [{ test: testNotBlank }],
    },
    anvil: {
      defaults: {
        onSuccess: () => {
          setInputAnvilMessage(undefined);
        },
        value: inputAnvilValue,
      },
      isRequired: true,
      tests: [{ test: testNotBlank }],
    },
    optimizeForOS: {
      defaults: {
        onSuccess: () => {
          setInputOptimizeForOSMessage(undefined);
        },
        value: inputOptimizeForOSValue?.key,
      },
      isRequired: true,
      tests: [{ test: testNotBlank }],
    },
  };
  virtualDisks.inputSizeMessages.forEach((message, vdIndex) => {
    inputTests[`vd${vdIndex}Size`] = {
      defaults: {
        displayMax: `${virtualDisks.inputMaxes[vdIndex]} ${virtualDisks.inputUnits[vdIndex]}`,
        displayMin: displayVirtualDiskSizeMin,
        max: virtualDisks.maxes[vdIndex],
        min: VIRTUAL_DISK_SIZE_MIN,
        onSuccess: () => {
          virtualDisks.inputSizeMessages[vdIndex] = undefined;
        },
        value: virtualDisks.sizes[vdIndex],
      },
      isRequired: true,
      onFinishBatch: () => {
        setVirtualDisks({ ...virtualDisks });
      },
      tests: [
        {
          onFailure: () => {
            virtualDisks.inputSizeMessages[vdIndex] = {
              text: 'Non available.',
              type: 'warning',
            };
          },
          test: testMax,
        },
        {
          onFailure: ({ displayMax, displayMin }) => {
            virtualDisks.inputSizeMessages[vdIndex] = {
              text: `Virtual disk ${vdIndex} size is expected to be between ${displayMin} and ${displayMax}.`,
              type: 'warning',
            };
          },
          test: testRange,
        },
      ],
    };

    inputTests[`vd${vdIndex}StorageGroup`] = {
      defaults: {
        onSuccess: () => {
          virtualDisks.inputStorageGroupUUIDMessages[vdIndex] = undefined;
        },
        value: virtualDisks.inputStorageGroupUUIDs[vdIndex],
      },
      isRequired: true,
      onFinishBatch: () => {
        setVirtualDisks({ ...virtualDisks });
      },
      tests: [{ test: testNotBlank }],
    };
  });

  const updateLimits: UpdateLimitsFunction = ({
    allAnvils: ulAllAnvils = allAnvils,
    cpuCores: ulCPUCores = inputCPUCoresValue,
    fileUUIDs: ulFileUUIDs = [inputInstallISOFileUUID, inputDriverISOFileUUID],
    includeAnvilUUIDs: ulIncludeAnvilUUIDs = filterBlanks([inputAnvilValue]),
    includeFileUUIDs: ulIncludeFileUUIDs,
    includeStorageGroupUUIDs: ulIncludeStorageGroupUUIDs,
    inputMemoryUnit: ulInputMemoryUnit = inputMemoryUnit,
    memory: ulMemory = memory,
    storageGroupUUIDMapToData:
      ulStorageGroupUUIDMapToData = storageGroupUUIDMapToData,
    virtualDisks: ulVirtualDisks = virtualDisks,
  } = {}) => {
    const {
      anvilUUIDs,
      fileUUIDs,
      maxCPUCores,
      maxMemory,
      maxVirtualDiskSizes,
      storageGroupUUIDs,
    } = filterAnvils(
      ulAllAnvils,
      ulStorageGroupUUIDMapToData,
      ulCPUCores,
      ulMemory,
      ulVirtualDisks.sizes,
      ulVirtualDisks.inputStorageGroupUUIDs,
      ulFileUUIDs,
      {
        includeAnvilUUIDs: ulIncludeAnvilUUIDs,
        includeFileUUIDs: ulIncludeFileUUIDs,
        includeStorageGroupUUIDs: ulIncludeStorageGroupUUIDs,
      },
    );

    setInputCPUCoresMax(maxCPUCores);
    setMemoryMax(maxMemory);

    const formattedMaxVDSizes: string[] = [];

    ulVirtualDisks.maxes = maxVirtualDiskSizes;
    ulVirtualDisks.maxes.forEach((vdMaxSize, vdIndex) => {
      dsize(vdMaxSize, {
        fromUnit: 'B',
        onSuccess: {
          string: (value, unit) => {
            ulVirtualDisks.inputMaxes[vdIndex] = value;
            formattedMaxVDSizes[vdIndex] = `${value} ${unit}`;
          },
        },
        toUnit: ulVirtualDisks.inputUnits[vdIndex],
      });
    });
    setVirtualDisks({ ...ulVirtualDisks });

    setIncludeAnvilUUIDs(anvilUUIDs);
    setIncludeFileUUIDs(fileUUIDs);
    setIncludeStorageGroupUUIDs(storageGroupUUIDs);

    let formattedMaxMemory = '';

    dsize(maxMemory, {
      fromUnit: 'B',
      onSuccess: {
        string: (value, unit) => {
          setInputMemoryMax(value);
          formattedMaxMemory = `${value} ${unit}`;
        },
      },
      toUnit: ulInputMemoryUnit,
    });

    return {
      formattedMaxMemory,
      formattedMaxVDSizes,
      maxCPUCores,
      maxMemory,
      maxVirtualDiskSizes,
    };
  };
  // The memorized version of updateLimits() should only be called during first render.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const initLimits = useCallback(updateLimits, []);

  const testInput = (
    ...[options, ...restArgs]: Parameters<TestInputFunction>
  ) => baseTestInput({ tests: inputTests, ...options }, ...restArgs);

  const changeMemory = ({
    cmValue = BIGINT_ZERO,
    cmUnit = inputMemoryUnit,
  }: { cmValue?: bigint; cmUnit?: DataSizeUnit } = {}) => {
    setMemory(cmValue);

    const { formattedMaxMemory, maxMemory } = updateLimits({
      inputMemoryUnit: cmUnit,
      memory: cmValue,
    });

    testInput({
      inputs: {
        memory: {
          displayMax: formattedMaxMemory,
          max: maxMemory,
          value: cmValue,
        },
      },
    });
  };

  const handleInputMemoryValueChange = ({
    value = inputMemoryValue,
    unit = inputMemoryUnit,
  }: {
    value?: string;
    unit?: DataSizeUnit;
  } = {}) => {
    if (value !== inputMemoryValue) {
      setInputMemoryValue(value);
    }

    if (unit !== inputMemoryUnit) {
      setInputMemoryUnit(unit);
    }

    dsizeToByte(
      value,
      unit,
      (convertedMemory) =>
        changeMemory({ cmValue: convertedMemory, cmUnit: unit }),
      () => changeMemory({ cmUnit: unit }),
    );
  };

  const handleInputInstallISOFileUUIDChange = (uuid: string) => {
    setInputInstallISOFileUUID(uuid);

    updateLimits({
      fileUUIDs: [uuid, inputDriverISOFileUUID],
    });
  };

  const handleInputDriverISOFileUUIDChange = (uuid: string) => {
    setInputDriverISOFileUUID(uuid);

    updateLimits({
      fileUUIDs: [inputInstallISOFileUUID, uuid],
    });
  };

  const handleInputAnvilValueChange = (uuid: string) => {
    const havcIncludeAnvilUUIDs = filterBlanks([uuid]);

    setInputAnvilValue(uuid);

    updateLimits({
      includeAnvilUUIDs: havcIncludeAnvilUUIDs,
    });
  };

  const createConfirmDialogContent = () => {
    const gridColumns = 10;
    const c1 = 2;
    const c2 = 5;
    const c3 = 3;
    const c2n3 = c2 + c3;

    return (
      <Grid container columns={gridColumns} direction="column">
        <Grid item xs={gridColumns}>
          <BodyText>
            Server <InlineMonoText text={inputServerNameValue} /> will be
            created on anvil node{' '}
            <InlineMonoText
              text={anvilUUIDMapToData[inputAnvilValue].anvilName}
            />{' '}
            with the following properties:
          </BodyText>
        </Grid>
        <Grid container direction="row" item xs={gridColumns}>
          <Grid item xs={c1}>
            <BodyText text="CPU" />
          </Grid>
          <Grid item xs={c2}>
            <BodyText>
              <InlineMonoText edge="start">{inputCPUCoresValue}</InlineMonoText>{' '}
              core(s)
            </BodyText>
          </Grid>
          <Grid item xs={c3}>
            <BodyText>
              <InlineMonoText edge="start">{inputCPUCoresMax}</InlineMonoText>{' '}
              core(s) available
            </BodyText>
          </Grid>
        </Grid>
        <Grid container direction="row" item xs={gridColumns}>
          <Grid item xs={c1}>
            <BodyText text="Memory" />
          </Grid>
          <Grid item xs={c2}>
            <BodyText>
              <InlineMonoText edge="start">
                {inputMemoryValue} {inputMemoryUnit}
              </InlineMonoText>
            </BodyText>
          </Grid>
          <Grid item xs={c3}>
            <BodyText>
              <InlineMonoText edge="start">
                {inputMemoryMax} {inputMemoryUnit}
              </InlineMonoText>{' '}
              available
            </BodyText>
          </Grid>
        </Grid>
        {virtualDisks.stateIds.map((vdStateId, vdIndex) => {
          const vdInputMax = virtualDisks.inputMaxes[vdIndex];
          const vdInputSize = virtualDisks.inputSizes[vdIndex];
          const vdInputUnit = virtualDisks.inputUnits[vdIndex];
          const vdStorageGroupName =
            storageGroupUUIDMapToData[
              virtualDisks.inputStorageGroupUUIDs[vdIndex]
            ].storageGroupName;

          return (
            <Grid
              container
              direction="row"
              key={`ps-virtual-disk-${vdStateId}-summary`}
              item
              xs={gridColumns}
            >
              <Grid item xs={c1}>
                <BodyText>
                  Disk <InlineMonoText text={vdIndex} />
                </BodyText>
              </Grid>
              <Grid item xs={c2}>
                <BodyText>
                  <InlineMonoText edge="start">
                    {vdInputSize} {vdInputUnit}
                  </InlineMonoText>{' '}
                  on <InlineMonoText>{vdStorageGroupName}</InlineMonoText>
                </BodyText>
              </Grid>
              <Grid item xs={c3}>
                <BodyText>
                  <InlineMonoText edge="start">
                    {vdInputMax} {vdInputUnit}
                  </InlineMonoText>{' '}
                  available
                </BodyText>
              </Grid>
            </Grid>
          );
        })}
        <Grid container direction="row" item xs={gridColumns}>
          <Grid item xs={c1}>
            <BodyText text="Install ISO" />
          </Grid>
          <Grid item xs={c2n3}>
            <BodyText>
              <InlineMonoText edge="start">
                {fileUUIDMapToData[inputInstallISOFileUUID].fileName}
              </InlineMonoText>
            </BodyText>
          </Grid>
        </Grid>
        <Grid container direction="row" item xs={gridColumns}>
          <Grid item xs={c1}>
            <BodyText text="Driver ISO" />
          </Grid>
          <Grid item xs={c2n3}>
            <BodyText>
              {fileUUIDMapToData[inputDriverISOFileUUID] ? (
                <InlineMonoText edge="start">
                  {fileUUIDMapToData[inputDriverISOFileUUID].fileName}
                </InlineMonoText>
              ) : (
                'none'
              )}
            </BodyText>
          </Grid>
        </Grid>
        <Grid container direction="row" item xs={gridColumns}>
          <Grid item xs={c1}>
            <BodyText text="Optimize for OS" />
          </Grid>
          <Grid item xs={c2n3}>
            <BodyText>
              <InlineMonoText edge="start">{`${inputOptimizeForOSValue?.label}`}</InlineMonoText>
            </BodyText>
          </Grid>
        </Grid>
      </Grid>
    );
  };

  const hasResource = useMemo<Record<string, boolean>>(
    () => ({
      'anvil node': Boolean(Object.keys(anvilUUIDMapToData).length),
      file: Boolean(Object.keys(fileUUIDMapToData).length),
      'storage group': Boolean(Object.keys(storageGroupUUIDMapToData).length),
    }),
    [anvilUUIDMapToData, fileUUIDMapToData, storageGroupUUIDMapToData],
  );

  const { validating } = useFetch<
    AnvilDetailForProvisionServer,
    ProvisionServerStructures
  >(`/anvil?anvilUUIDs=all&isForProvisionServer=1`, {
    onSuccess: (data) => {
      const {
        anvils: ueAllAnvils,
        anvilSelectItems: ueAnvilSelectItems,
        anvilUUIDMapToData: ueAnvilUUIDMapToData,
        fileSelectItems: ueFileSelectItems,
        fileUUIDMapToData: ueFileUUIDMapToData,
        serverNameMapToData: ueServerNameMapToData,
        storageGroupSelectItems: ueStorageGroupSelectItems,
        storageGroupUUIDMapToData: ueStorageGroupUUIDMapToData,
      } = organizeAnvils(data.anvils);

      setAllAnvils(ueAllAnvils);
      setAnvilUUIDMapToData(ueAnvilUUIDMapToData);
      setFileUUIDMapToData(ueFileUUIDMapToData);
      setServerNameMapToData(ueServerNameMapToData);
      setStorageGroupUUIDMapToData(ueStorageGroupUUIDMapToData);

      setAnvilSelectItems(ueAnvilSelectItems);
      setFileSelectItems(ueFileSelectItems);
      setStorageGroupSelectItems(ueStorageGroupSelectItems);

      const limits: Parameters<UpdateLimitsFunction>[0] = {
        allAnvils: ueAllAnvils,
        storageGroupUUIDMapToData: ueStorageGroupUUIDMapToData,
      };

      // Auto-select the only option when there's only 1.
      // Reminder to update the form limits after changing any value.

      if (ueAnvilSelectItems.length === 1) {
        const {
          0: { value: uuid },
        } = ueAnvilSelectItems;

        setInputAnvilValue(uuid);

        limits.includeAnvilUUIDs = [uuid];
      }

      if (ueFileSelectItems.length === 1) {
        const {
          0: { value: uuid },
        } = ueFileSelectItems;

        setInputInstallISOFileUUID(uuid);

        limits.fileUUIDs = [uuid, ''];
      }

      if (ueStorageGroupSelectItems.length === 1) {
        const {
          0: { value: uuid },
        } = ueStorageGroupSelectItems;

        setVirtualDisks((previous) => {
          const current = { ...previous };

          current.inputStorageGroupUUIDs[0] = uuid;

          limits.virtualDisks = current;

          return current;
        });
      }

      initLimits(limits);

      setOSAutocompleteOptions(
        Object.entries(data.oses).map(([key, label]) => ({
          key,
          label,
        })),
      );

      setIsProvisionServerDataReady(true);
    },
    refreshInterval: 5000,
  });

  return (
    <>
      <Dialog
        fullWidth
        maxWidth="sm"
        open={open}
        PaperComponent={Panel}
        PaperProps={{
          sx: {
            overflow: 'visible',
          },
        }}
      >
        <PanelHeader>
          <HeaderText>Provision a server</HeaderText>
          <SyncIndicator syncing={validating} />
          <IconButton
            mapPreset="close"
            onClick={onCloseProvisionServerDialog}
            size="small"
          />
        </PanelHeader>
        <FlexBox spacing=".6em">
          {Object.entries(hasResource).map(
            ([resource, has]) =>
              !has && (
                <MessageBox type="warning">
                  No {resource} available yet. It will appear shortly after
                  creation.
                </MessageBox>
              ),
          )}
        </FlexBox>
        {isProvisionServerDataReady ? (
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              maxHeight: '50vh',
              overflowY: 'scroll',
              paddingTop: '.6em',

              '& > :not(:first-child)': {
                marginTop: '1em',
              },
            }}
          >
            <OutlinedInputWithLabel
              id="ps-server-name"
              label="Server name"
              inputProps={{
                onChange: ({ target: { value } }) => {
                  setInputServerNameValue(value);

                  testInput({ inputs: { serverName: { value } } });
                },
                value: inputServerNameValue,
              }}
              inputLabelProps={{
                isNotifyRequired: inputServerNameValue.length === 0,
              }}
              messageBoxProps={inputServerNameMessage}
            />
            <Autocomplete
              id="ps-cpu-cores"
              disableClearable
              extendRenderInput={({ inputLabelProps = {} }) => {
                inputLabelProps.isNotifyRequired = inputCPUCoresValue <= 0;
              }}
              getOptionLabel={(option) => String(option)}
              label="CPU cores"
              messageBoxProps={inputCPUCoresMessage}
              noOptionsText="No available number of cores."
              onChange={(event, value) => {
                if (!value || value === inputCPUCoresValue) return;

                setInputCPUCoresValue(value);

                const { maxCPUCores: newCPUCoresMax } = updateLimits({
                  cpuCores: value,
                });

                testInput({
                  inputs: {
                    cpuCores: {
                      max: newCPUCoresMax,
                      value,
                    },
                  },
                });
              }}
              openOnFocus
              options={inputCpuCoresOptions}
              renderOption={(optionProps, option) => (
                <li {...optionProps} key={`ps-cpu-cores-${option}`}>
                  {option}
                </li>
              )}
              value={inputCPUCoresValue}
            />
            <OutlinedLabeledInputWithSelect
              id="ps-memory"
              label="Memory"
              messageBoxProps={inputMemoryMessage}
              inputWithLabelProps={{
                inputProps: {
                  endAdornment: createMaxValueButton(
                    `${inputMemoryMax} ${inputMemoryUnit}`,
                    {
                      onButtonClick: () => {
                        setInputMemoryValue(inputMemoryMax);
                        changeMemory({ cmValue: memoryMax });
                      },
                    },
                  ),
                  onChange: ({ target: { value } }) => {
                    handleInputMemoryValueChange({ value });
                  },
                  type: 'number',
                  value: inputMemoryValue,
                },
                inputLabelProps: {
                  isNotifyRequired: memory === BIGINT_ZERO,
                },
              }}
              selectItems={DSIZE_SELECT_ITEMS}
              selectWithLabelProps={{
                selectProps: {
                  onChange: ({ target: { value } }) => {
                    const selectedUnit = value as DataSizeUnit;

                    handleInputMemoryValueChange({ unit: selectedUnit });
                  },
                  value: inputMemoryUnit,
                },
              }}
            />
            {virtualDisks.stateIds.map((vdStateId, vdIndex) =>
              createVirtualDiskForm(
                virtualDisks,
                vdIndex,
                setVirtualDisks,
                storageGroupSelectItems,
                includeStorageGroupUUIDs,
                updateLimits,
                storageGroupUUIDMapToData,
                testInput,
              ),
            )}
            <SelectWithLabel
              disableItem={(value) => value === inputDriverISOFileUUID}
              hideItem={(value) => !includeFileUUIDs.includes(value)}
              id="ps-install-image"
              inputLabelProps={{
                isNotifyRequired: inputInstallISOFileUUID.length === 0,
              }}
              label="Install ISO"
              messageBoxProps={inputInstallISOMessage}
              selectItems={fileSelectItems}
              selectProps={{
                onChange: ({ target: { value } }) => {
                  const newInstallISOFileUUID = value as string;

                  handleInputInstallISOFileUUIDChange(newInstallISOFileUUID);
                },
                onClearIndicatorClick: () =>
                  handleInputInstallISOFileUUIDChange(''),
                value: inputInstallISOFileUUID,
              }}
            />
            <SelectWithLabel
              disableItem={(value) => value === inputInstallISOFileUUID}
              hideItem={(value) => !includeFileUUIDs.includes(value)}
              id="ps-driver-image"
              label="Driver ISO"
              messageBoxProps={inputDriverISOMessage}
              selectItems={fileSelectItems}
              selectProps={{
                onChange: ({ target: { value } }) => {
                  const newDriverISOFileUUID = value as string;

                  handleInputDriverISOFileUUIDChange(newDriverISOFileUUID);
                },
                onClearIndicatorClick: () =>
                  handleInputDriverISOFileUUIDChange(''),
                value: inputDriverISOFileUUID,
              }}
            />
            <SelectWithLabel
              disableItem={(value) => !includeAnvilUUIDs.includes(value)}
              id="ps-anvil"
              inputLabelProps={{
                isNotifyRequired: inputAnvilValue.length === 0,
              }}
              label="Anvil node"
              messageBoxProps={inputAnvilMessage}
              selectItems={anvilSelectItems}
              selectProps={{
                onChange: ({ target: { value } }) => {
                  const newAnvilUUID: string = value as string;

                  handleInputAnvilValueChange(newAnvilUUID);
                },
                onClearIndicatorClick: () => handleInputAnvilValueChange(''),
                renderValue: (value) => {
                  const { anvilName: rvAnvilName = `Unknown ${value}` } =
                    anvilUUIDMapToData[value as string] ?? {};

                  return rvAnvilName;
                },
                value: inputAnvilValue,
              }}
            />
            <Autocomplete
              id="ps-optimize-for-os"
              extendRenderInput={({ inputLabelProps = {} }) => {
                inputLabelProps.isNotifyRequired =
                  inputOptimizeForOSValue === null;
              }}
              isOptionEqualToValue={(option, value) => option.key === value.key}
              label="Optimize for OS"
              messageBoxProps={inputOptimizeForOSMessage}
              noOptionsText="No matching OS"
              onChange={(event, value) => {
                setInputOptimizeForOSValue(value);
              }}
              openOnFocus
              options={osAutocompleteOptions}
              renderOption={(optionProps, option) => (
                <li {...optionProps} key={`ps-optimize-for-os-${option.key}`}>
                  {option.label} ({option.key})
                </li>
              )}
              value={inputOptimizeForOSValue}
            />
          </Box>
        ) : (
          <Spinner />
        )}
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            marginTop: '1em',

            '& > :not(:first-child)': {
              marginTop: '1em',
            },
          }}
        >
          {successfulProvisionCount > 0 && (
            <MessageBox
              isAllowClose
              text="Provision server job registered. You can provision another server, or exit; it won't affect the registered job."
            />
          )}
          {isProvisionRequestInProgress ? (
            <Spinner mt={0} />
          ) : (
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'row',
                justifyContent: 'flex-end',
                width: '100%',
              }}
            >
              <ContainedButton
                background="blue"
                disabled={!testInput({ isIgnoreOnCallbacks: true })}
                onClick={() => {
                  setIsOpenProvisionConfirmDialog(true);
                }}
              >
                Provision
              </ContainedButton>
            </Box>
          )}
        </Box>
      </Dialog>
      {isOpenProvisionConfirmDialog && (
        <ConfirmDialog
          actionProceedText="Provision"
          content={createConfirmDialogContent()}
          dialogProps={{ open: isOpenProvisionConfirmDialog }}
          onCancelAppend={() => {
            setIsOpenProvisionConfirmDialog(false);
          }}
          onProceedAppend={() => {
            const requestBody = {
              serverName: inputServerNameValue,
              cpuCores: inputCPUCoresValue,
              memory: memory.toString(),
              virtualDisks: virtualDisks.stateIds.map((vdStateId, vdIndex) => ({
                storageSize: virtualDisks.sizes[vdIndex].toString(),
                storageGroupUUID: virtualDisks.inputStorageGroupUUIDs[vdIndex],
              })),
              installISOFileUUID: inputInstallISOFileUUID,
              driverISOFileUUID: inputDriverISOFileUUID,
              anvilUUID: inputAnvilValue,
              optimizeForOS: inputOptimizeForOSValue?.key,
            };

            setIsProvisionRequestInProgress(true);

            api.post('/server', requestBody).then(() => {
              setIsProvisionRequestInProgress(false);
              setSuccessfulProvisionCount(successfulProvisionCount + 1);
            });

            setIsOpenProvisionConfirmDialog(false);
          }}
          titleText={`Provision ${inputServerNameValue}?`}
        />
      )}
    </>
  );
};

export default ProvisionServerDialog;
