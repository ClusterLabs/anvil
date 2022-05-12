import {
  Dispatch,
  ReactNode,
  SetStateAction,
  useCallback,
  useEffect,
  useState,
} from 'react';
import { Box, Dialog, DialogProps, InputAdornment } from '@mui/material';
import { DataSizeUnit } from 'format-data-size';
import { v4 as uuidv4 } from 'uuid';

import Autocomplete from './Autocomplete';
import ContainedButton, { ContainedButtonProps } from './ContainedButton';
import { dsize, dsizeToByte } from '../lib/format_data_size_wrappers';
import { MessageBoxProps } from './MessageBox';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import SelectWithLabel, { SelectItem } from './SelectWithLabel';
import Slider, { SliderProps } from './Slider';
import {
  testInput as baseTestInput,
  testMax,
  testNotBlank,
  testRange,
} from '../lib/test_input';
import {
  InputTestBatches,
  TestInputFunction,
} from '../types/TestInputFunction';
import { BodyText, HeaderText } from './Text';
import OutlinedLabeledInputWithSelect from './OutlinedLabeledInputWithSelect';
import ConfirmDialog from './ConfirmDialog';

type InputMessage = Partial<Pick<MessageBoxProps, 'type' | 'text'>>;

type ProvisionServerDialogProps = {
  dialogProps: DialogProps;
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
  servers: Array<
    Omit<ServerMetadataForProvisionServer, 'serverMemory'> & {
      serverMemory: bigint;
    }
  >;
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

const MOCK_DATA = {
  anvils: [
    {
      anvilUUID: 'ad590bcb-24e1-4592-8cd1-9cd6229b7bf2',
      anvilName: 'yan-anvil-03',
      anvilDescription: "Yan's test Anvil specialized for breaking things.",
      anvilTotalCPUCores: 4,
      anvilTotalMemory: '17179869184',
      anvilTotalAllocatedCPUCores: 1,
      anvilTotalAllocatedMemory: '1073741824',
      anvilTotalAvailableCPUCores: 3,
      anvilTotalAvailableMemory: '7516192768',
      hosts: [
        {
          hostUUID: 'c9b25b77-f9a1-41fa-9f04-677c58d0d9e1',
          hostName: 'yan-a03n01.alteeve.com',
          hostCPUCores: 4,
          hostMemory: '17179869184',
        },
        {
          hostUUID: 'c0a1c2c8-3418-4dbc-80c6-c4c0cea6a511',
          hostName: 'yan-a03n02.alteeve.com',
          hostCPUCores: 4,
          hostMemory: '17179869184',
        },
        {
          hostUUID: '8815a6dd-239d-4f8d-b248-ac8a5cac4a30',
          hostName: 'yan-a03dr01.alteeve.com',
          hostCPUCores: 4,
          hostMemory: '17179869184',
        },
      ],
      servers: [
        {
          serverUUID: 'd128c15a-0e21-4ba3-9084-1972dad31bd4',
          serverName: 'alpine-x86_64-01',
          serverCPUCores: 1,
          serverMemory: '1073741824',
        },
      ],
      storageGroups: [
        {
          storageGroupUUID: 'b594f417-852a-4bd4-a215-fae32d226b0b',
          storageGroupName: 'Storage group 1',
          storageGroupSize: '137325707264',
          storageGroupFree: '42941284352',
        },
      ],
      files: [
        {
          fileUUID: '5d6fc6d9-03f8-40ec-9bff-38e31b3a5bc5',
          fileName: 'alpine-virt-3.15.0-x86_64.iso',
        },
      ],
    },
    {
      anvilUUID: '85e0fd96-ea38-403d-992f-441d20cad679',
      anvilName: 'mock-anvil-01',
      anvilDescription: 'Randomly generated mock Anvil #1.',
      anvilTotalCPUCores: 8,
      anvilTotalMemory: '34359738368',
      anvilTotalAllocatedCPUCores: 0,
      anvilTotalAllocatedMemory: '2147483648',
      anvilTotalAvailableCPUCores: 8,
      anvilTotalAvailableMemory: '32212254720',
      hosts: [
        {
          hostUUID: '2198ae4a-db3a-4685-8d98-db56af75d53d',
          hostName: 'mock-a03n01.alteeve.com',
          hostCPUCores: 8,
          hostMemory: '34359738368',
        },
        {
          hostUUID: '928f12b4-1be0-4872-adbc-f78579323d50',
          hostName: 'mock-a03n02.alteeve.com',
          hostCPUCores: 8,
          hostMemory: '34359738368',
        },
        {
          hostUUID: 'c4837341-fd09-4b36-b1f0-e16115b704b4',
          hostName: 'mock-a03dr01.alteeve.com',
          hostCPUCores: 8,
          hostMemory: '34359738368',
        },
      ],
      servers: [],
      storageGroups: [
        {
          storageGroupUUID: '271651b0-c064-401b-9391-549bbced2383',
          storageGroupName: 'Mock storage group 1',
          storageGroupSize: '274651414528',
          storageGroupFree: '85882568704',
        },
        {
          storageGroupUUID: '1d57d618-9c6a-4fda-bcc3-d9014ea55161',
          storageGroupName: 'Mock storage group 2',
          storageGroupSize: '205988560896',
          storageGroupFree: '171765137408',
        },
      ],
      files: [
        {
          fileUUID: '5d6fc6d9-03f8-40ec-9bff-38e31b3a5bc5',
          fileName: 'alpine-virt-3.15.0-x86_64.iso',
        },
      ],
    },
    {
      anvilUUID: '68470d36-e46b-44a5-b2cd-d57b2e7b5ddb',
      anvilName: 'mock-anvil-02',
      anvilDescription: 'Randomly generated mock Anvil #2.',
      anvilTotalCPUCores: 16,
      anvilTotalMemory: '1234567890',
      anvilTotalAllocatedCPUCores: 7,
      anvilTotalAllocatedMemory: '12345',
      anvilTotalAvailableCPUCores: 9,
      anvilTotalAvailableMemory: '1234555545',
      hosts: [
        {
          hostUUID: 'ee1f4852-b3bc-44ca-93b7-8000c3063292',
          hostName: 'mock-a03n01.alteeve.com',
          hostCPUCores: 16,
          hostMemory: '1234567890',
        },
        {
          hostUUID: '26f9d3c4-0f91-4266-9f6f-1309e521c693',
          hostName: 'mock-a03n02.alteeve.com',
          hostCPUCores: 16,
          hostMemory: '1234567890',
        },
        {
          hostUUID: 'eb1b1bd6-2caa-4907-ac68-7dba465b7a67',
          hostName: 'mock-a03dr01.alteeve.com',
          hostCPUCores: 16,
          hostMemory: '1234567890',
        },
      ],
      servers: [],
      storageGroups: [],
      files: [],
    },
  ],
  osList: [
    'os_list_almalinux8,AlmaLinux 8',
    'os_list_alpinelinux3.14,Alpine Linux 3.14',
    'os_list_alt.p10,ALT p10 StarterKits',
    'os_list_alt9.1,ALT 9.1',
    'os_list_alt9.2,ALT 9.2',
    'os_list_centos-stream9,CentOS Stream 9',
    'os_list_cirros0.5.0,CirrOS 0.5.0',
    'os_list_cirros0.5.1,CirrOS 0.5.1',
    'os_list_cirros0.5.2,CirrOS 0.5.2',
    'os_list_debian11,Debian 11',
    'os_list_fedora34,Fedora 34',
    'os_list_freebsd13.0,FreeBSD 13.0',
    'os_list_haikur1beta2,Haiku R1/Beta2',
    'os_list_haikur1beta3,Haiku R1/Beta3',
    'os_list_mageia8,Mageia 8',
    'os_list_nixos-21.05,NixOS 21.05',
    'os_list_openbsd6.8,OpenBSD 6.8',
    'os_list_openbsd6.9,OpenBSD 6.9',
    'os_list_opensuse15.3,openSUSE Leap 15.3',
    'os_list_rhel8.5,Red Hat Enterprise Linux 8.5',
    'os_list_silverblue34,Fedora Silverblue 34',
    'os_list_sle15sp3,SUSE Linux Enterprise 15 SP3',
    'os_list_slem5.0,SUSE Linux Enterprise Micro',
    'os_list_ubuntu21.04,Ubuntu 21.04',
    'os_list_win2k22,Microsoft Windows Server 2022',
  ],
};

const BIGINT_ZERO = BigInt(0);

const DATA_SIZE_UNIT_SELECT_ITEMS: SelectItem<DataSizeUnit>[] = [
  { value: 'B' },
  { value: 'KiB' },
  { value: 'MiB' },
  { value: 'GiB' },
  { value: 'TiB' },
];

const INITIAL_DATA_SIZE_UNIT: DataSizeUnit = 'GiB';

const createOutlinedSlider = (
  id: string,
  label: string,
  value: number,
  sliderProps?: Partial<SliderProps>,
): JSX.Element => (
  <Slider
    // eslint-disable-next-line react/jsx-props-no-spreading
    {...{
      isAllowTextInput: true,
      label,
      labelId: `${id}-label`,
      value,
      ...sliderProps,
    }}
  />
);

const createMaxValueButton = (
  maxValue: string,
  {
    onButtonClick,
  }: {
    onButtonClick?: ContainedButtonProps['onClick'];
  },
) => (
  <InputAdornment position="end">
    <ContainedButton
      disabled={onButtonClick === undefined}
      onClick={onButtonClick}
      sx={{
        marginLeft: '14px',
        minWidth: 'unset',
        whiteSpace: 'nowrap',
      }}
    >{`Max: ${maxValue}`}</ContainedButton>
  </InputAdornment>
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
        servers: servers.map((server) => ({
          ...server,
          serverMemory: BigInt(server.serverMemory),
        })),
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

        // Summarize storage groups in this anvil node pair to produce all
        // UUIDs, max free space, and total free space.
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
          // Does this anvil node pair have at least one storage group?
          () => storageGroups.length > 0,
          // Does this anvil node pair have enough CPU cores?
          () => cpuCores <= anvilTotalCPUCores,
          // Does this anvil node pair have enough memory?
          () => memory <= anvilTotalAvailableMemory,
          // For every virtual disk:
          // 1. Does this anvil node pair have the selected storage group which
          //    will contain the VD?
          // 2. Does the selected storage group OR any storage group on this
          //    anvil node pair have enough free space?
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
          // Do storage groups on this anvil node pair have enough free space
          // to contain multiple VDs?
          () =>
            Object.entries(storageGroupTotals).every(([uuid, total]) =>
              uuid === 'all'
                ? total <= anvilStorageGroupFreeTotal
                : total <= storageGroupUUIDMapToData[uuid].storageGroupFree,
            ),
          // Does this anvil node pair have access to selected files?
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

// const convertSelectValueToArray = (value: unknown) =>
//   typeof value === 'string' ? value.split(',') : (value as string[]);

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
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
        <OutlinedLabeledInputWithSelect
          id={`ps-virtual-disk-size-${vdIndex}`}
          label="Virtual disk size"
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
          selectItems={DATA_SIZE_UNIT_SELECT_ITEMS}
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
      </Box>
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
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

const ProvisionServerDialog = ({
  dialogProps: { open },
}: ProvisionServerDialogProps): JSX.Element => {
  const inputCPUCoresMin = 1;

  const [allAnvils, setAllAnvils] = useState<
    OrganizedAnvilDetailMetadataForProvisionServer[]
  >([]);
  const [anvilUUIDMapToData, setAnvilUUIDMapToData] =
    useState<AnvilUUIDMapToData>({});
  const [fileUUIDMapToData, setFileUUIDMapToData] = useState<FileUUIDMapToData>(
    {},
  );
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

  const [isOpenProvisionConfirmDialog, setIsOpenProvisionConfirmDialog] =
    useState<boolean>(false);

  const inputTests: InputTestBatches = {
    serverName: {
      defaults: {
        max: 0,
        min: 0,
        onSuccess: () => {
          setInputServerNameMessage(undefined);
        },
        value: inputServerNameValue,
      },
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
      ],
    },
    cpuCores: {
      defaults: {
        max: inputCPUCoresMax,
        min: inputCPUCoresMin,
        onSuccess: () => {
          setInputCPUCoresMessage(undefined);
        },
        value: inputCPUCoresValue,
      },
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
        displayMin: '1 B',
        max: memoryMax,
        min: 1,
        onSuccess: () => {
          setInputMemoryMessage(undefined);
        },
        value: memory,
      },
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
        max: 0,
        min: 0,
        onSuccess: () => {
          setInputInstallISOMessage(undefined);
        },
        value: inputInstallISOFileUUID,
      },
      tests: [{ test: testNotBlank }],
    },
    anvil: {
      defaults: {
        max: 0,
        min: 0,
        onSuccess: () => {
          setInputAnvilMessage(undefined);
        },
        value: inputAnvilValue,
      },
      tests: [{ test: testNotBlank }],
    },
    optimizeForOS: {
      defaults: {
        max: 0,
        min: 0,
        onSuccess: () => {
          setInputOptimizeForOSMessage(undefined);
        },
        value: inputOptimizeForOSValue?.key,
      },
      tests: [{ test: testNotBlank }],
    },
  };
  virtualDisks.inputSizeMessages.forEach((message, vdIndex) => {
    inputTests[`vd${vdIndex}Size`] = {
      defaults: {
        displayMax: `${virtualDisks.inputMaxes[vdIndex]} ${virtualDisks.inputUnits[vdIndex]}`,
        displayMin: '1 B',
        max: virtualDisks.maxes[vdIndex],
        min: 1,
        onSuccess: () => {
          virtualDisks.inputSizeMessages[vdIndex] = undefined;
        },
        value: virtualDisks.sizes[vdIndex],
      },
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
        max: 0,
        min: 0,
        onSuccess: () => {
          virtualDisks.inputStorageGroupUUIDMessages[vdIndex] = undefined;
        },
        value: virtualDisks.inputStorageGroupUUIDs[vdIndex],
      },
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

  useEffect(() => {
    const data = MOCK_DATA;

    const {
      anvils: ueAllAnvils,
      anvilSelectItems: ueAnvilSelectItems,
      anvilUUIDMapToData: ueAnvilUUIDMapToData,
      fileSelectItems: ueFileSelectItems,
      fileUUIDMapToData: ueFileUUIDMapToData,
      storageGroupSelectItems: ueStorageGroupSelectItems,
      storageGroupUUIDMapToData: ueStorageGroupUUIDMapToData,
    } = organizeAnvils(data.anvils);

    setAllAnvils(ueAllAnvils);
    setAnvilUUIDMapToData(ueAnvilUUIDMapToData);
    setFileUUIDMapToData(ueFileUUIDMapToData);
    setStorageGroupUUIDMapToData(ueStorageGroupUUIDMapToData);

    setAnvilSelectItems(ueAnvilSelectItems);
    setFileSelectItems(ueFileSelectItems);
    setStorageGroupSelectItems(ueStorageGroupSelectItems);

    initLimits({
      allAnvils: ueAllAnvils,
      storageGroupUUIDMapToData: ueStorageGroupUUIDMapToData,
    });

    setOSAutocompleteOptions(
      data.osList.map((keyValuePair) => {
        const [osKey, osValue] = keyValuePair.split(',');

        return {
          label: osValue,
          key: osKey,
        };
      }),
    );
  }, [initLimits]);

  return (
    <>
      <Dialog
        {...{
          fullWidth: true,
          maxWidth: 'sm',
          open,
          PaperComponent: Panel,
          PaperProps: { sx: { overflow: 'visible' } },
        }}
      >
        <PanelHeader>
          <HeaderText text="Provision a Server" />
        </PanelHeader>
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            maxHeight: '50vh',
            overflowY: 'scroll',
            paddingBottom: '.6em',
            paddingTop: '.6em',

            '& > :not(:first-child)': {
              marginTop: '1em',
            },
          }}
        >
          <Box sx={{ display: 'flex', flexDirection: 'column' }}>
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
          </Box>
          {createOutlinedSlider(
            'ps-cpu-cores',
            'CPU cores',
            inputCPUCoresValue,
            {
              messageBoxProps: inputCPUCoresMessage,
              sliderProps: {
                onChange: (value) => {
                  const newCPUCoresValue = value as number;

                  if (newCPUCoresValue !== inputCPUCoresValue) {
                    setInputCPUCoresValue(newCPUCoresValue);

                    const { maxCPUCores: newCPUCoresMax } = updateLimits({
                      cpuCores: newCPUCoresValue,
                    });

                    testInput({
                      inputs: {
                        cpuCores: {
                          max: newCPUCoresMax,
                          value: newCPUCoresValue,
                        },
                      },
                    });
                  }
                },
                max: inputCPUCoresMax,
                min: inputCPUCoresMin,
              },
            },
          )}
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
            selectItems={DATA_SIZE_UNIT_SELECT_ITEMS}
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
            label="Anvil node pair"
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
            value={inputOptimizeForOSValue}
          />
        </Box>
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'row',
            justifyContent: 'flex-end',
            marginTop: '1em',
            width: '100%',
          }}
        >
          <ContainedButton
            disabled={!testInput({ isIgnoreOnCallbacks: true })}
            onClick={() => {
              setIsOpenProvisionConfirmDialog(true);
            }}
          >
            Provision
          </ContainedButton>
        </Box>
      </Dialog>
      {isOpenProvisionConfirmDialog && (
        <ConfirmDialog
          actionProceedText="Provision"
          content={
            <Box sx={{ display: 'flex', flexDirection: 'column' }}>
              <BodyText
                text={`Server ${inputServerNameValue} will be created on anvil node pair ${anvilUUIDMapToData[inputAnvilValue].anvilName} with the following properties:`}
              />
              <BodyText text={`CPU: ${inputCPUCoresValue} core(s)`} />
              <BodyText
                text={`Memory: ${inputMemoryValue} ${inputMemoryUnit}`}
              />
              {virtualDisks.stateIds.map((vdStateId, vdIndex) => (
                <BodyText
                  key={`ps-virtual-disk-${vdStateId}-summary`}
                  text={`Virtual disk ${vdIndex}: ${
                    virtualDisks.inputSizes[vdIndex]
                  } ${virtualDisks.inputUnits[vdIndex]} on ${
                    storageGroupUUIDMapToData[
                      virtualDisks.inputStorageGroupUUIDs[vdIndex]
                    ].storageGroupName
                  }`}
                />
              ))}
              <BodyText
                text={`Install ISO: ${fileUUIDMapToData[inputInstallISOFileUUID].fileName}`}
              />
              <BodyText
                text={`Driver ISO: ${
                  fileUUIDMapToData[inputDriverISOFileUUID]?.fileName ?? 'none'
                }`}
              />
              <BodyText
                text={`Optimize for OS: ${inputOptimizeForOSValue?.label}`}
              />
            </Box>
          }
          dialogProps={{ open: isOpenProvisionConfirmDialog }}
          onCancel={() => {
            setIsOpenProvisionConfirmDialog(false);
          }}
          onProceed={() => {
            // const requestBody = {
            //   serverName: inputServerNameValue,
            //   cpuCores: inputCPUCoresValue,
            //   memory,
            //   virtualDisks: virtualDisks.stateIds.map((vdStateId, vdIndex) => ({
            //     size: virtualDisks.sizes[vdIndex],
            //     storageGroupUUID: virtualDisks.inputStorageGroupUUIDs[vdIndex],
            //   })),
            //   installISOFileUUID: inputInstallISOFileUUID,
            //   driverISOFileUUID: inputDriverISOFileUUID,
            //   anvilUUID: inputAnvilValue,
            //   optimizeForOS: inputOptimizeForOSValue?.key,
            // };

            setIsOpenProvisionConfirmDialog(false);
          }}
          titleText={`Provision ${inputServerNameValue}?`}
        />
      )}
    </>
  );
};

export default ProvisionServerDialog;
