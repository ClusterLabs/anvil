import {
  Dispatch,
  SetStateAction,
  useCallback,
  useEffect,
  useState,
} from 'react';
import { Box, Checkbox, Dialog, DialogProps, FormControl } from '@mui/material';
import {
  dSize as baseDSize,
  DataSizeUnit,
  FormatDataSizeOptions,
  FormatDataSizeInputValue,
} from 'format-data-size';

import Autocomplete from './Autocomplete';
import ContainedButton from './ContainedButton';
import MenuItem from './MenuItem';
import OutlinedInput from './OutlinedInput';
import OutlinedInputLabel from './OutlinedInputLabel';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import Select, { SelectProps } from './Select';
import Slider, { SliderProps } from './Slider';
import { BodyText, HeaderText } from './Text';

type SelectItem<SelectItemValueType = string> = {
  displayValue?: SelectItemValueType;
  value: SelectItemValueType;
};

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

type StorageGroupUUIDMapToFree = { [uuid: string]: bigint };

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

type FilterAnvilsFunction = (
  allAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  storageGroupUUIDMapToFree: StorageGroupUUIDMapToFree,
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
  maxes: bigint[];
  inputMaxes: string[];
  inputSizes: string[];
  inputStorageGroupUUIDs: string[];
  inputUnits: DataSizeUnit[];
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
  storageGroupUUIDMapToFree?: StorageGroupUUIDMapToFree;
  virtualDisks?: VirtualDiskStates;
}) => void;

const MOCK_DATA = {
  anvils: [
    {
      anvilUUID: 'ad590bcb-24e1-4592-8cd1-9cd6229b7bf2',
      anvilName: 'yan-anvil-03',
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

const DATA_SIZE_UNITS: SelectItem<DataSizeUnit>[] = [
  { value: 'B' },
  { value: 'KiB' },
  { value: 'MiB' },
  { value: 'GiB' },
  { value: 'TiB' },
  { value: 'kB' },
  { value: 'MB' },
  { value: 'GB' },
  { value: 'TB' },
];

const createOutlinedSelect = (
  id: string,
  label: string | undefined,
  selectItems: SelectItem[],
  {
    checkItem,
    disableItem,
    hideItem,
    selectProps,
    isCheckableItems = selectProps?.multiple,
  }: {
    checkItem?: (value: string) => boolean;
    disableItem?: (value: string) => boolean;
    hideItem?: (value: string) => boolean;
    isCheckableItems?: boolean;
    selectProps?: Partial<SelectProps>;
  } = {},
): JSX.Element => (
  <FormControl>
    {label && (
      <OutlinedInputLabel {...{ htmlFor: id }}>{label}</OutlinedInputLabel>
    )}
    <Select
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        id,
        input: <OutlinedInput {...{ label }} />,
        ...selectProps,
      }}
    >
      {selectItems.map(({ value, displayValue = value }) => (
        <MenuItem
          disabled={disableItem?.call(null, value)}
          key={`${id}-${value}`}
          sx={{
            display: hideItem?.call(null, value) ? 'none' : undefined,
          }}
          value={value}
        >
          {isCheckableItems && (
            <Checkbox checked={checkItem?.call(null, value)} />
          )}
          {displayValue}
        </MenuItem>
      ))}
    </Select>
  </FormControl>
);

const createOutlinedSlider = (
  id: string,
  label: string,
  value: number,
  sliderProps?: Partial<SliderProps>,
): JSX.Element => (
  <FormControl>
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
  </FormControl>
);

const createOutlinedInputWithSelect = (
  id: string,
  label: string,
  selectItems: SelectItem[],
  {
    inputWithLabelProps,
    selectProps,
  }: {
    inputWithLabelProps?: Partial<OutlinedInputWithLabelProps>;
    selectProps?: Partial<SelectProps>;
  } = {},
) => (
  <FormControl
    sx={{
      display: 'flex',
      flexDirection: 'row',

      '& > :first-child': {
        flexGrow: 1,
      },
    }}
  >
    <OutlinedInputWithLabel
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        id,
        label,
        ...inputWithLabelProps,
      }}
    />
    {createOutlinedSelect(`${id}-nested-select`, undefined, selectItems, {
      selectProps,
    })}
  </FormControl>
);

const organizeAnvils = (data: AnvilDetailMetadataForProvisionServer[]) => {
  const anvilFiles: Record<string, FileMetadataForProvisionServer> = {};
  const result = data.reduce<{
    anvils: OrganizedAnvilDetailMetadataForProvisionServer[];
    anvilSelectItems: SelectItem[];
    files: FileMetadataForProvisionServer[];
    fileSelectItems: SelectItem[];
    storageGroups: OrganizedStorageGroupMetadataForProvisionServer[];
    storageGroupSelectItems: SelectItem[];
    storageGroupUUIDMapToFree: StorageGroupUUIDMapToFree;
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
            const anvilStorageGroup = {
              ...storageGroup,
              anvilUUID,
              anvilName,
              storageGroupSize: BigInt(storageGroup.storageGroupSize),
              storageGroupFree: BigInt(storageGroup.storageGroupFree),
            };

            reducedStorageGroups.anvilStorageGroupUUIDs.push(
              storageGroup.storageGroupUUID,
            );
            reducedStorageGroups.anvilStorageGroups.push(anvilStorageGroup);

            reduceContainer.storageGroups.push(anvilStorageGroup);
            reduceContainer.storageGroupSelectItems.push({
              displayValue: `${anvilName} -- ${storageGroup.storageGroupName}`,
              value: storageGroup.storageGroupUUID,
            });
            reduceContainer.storageGroupUUIDMapToFree[
              storageGroup.storageGroupUUID
            ] = anvilStorageGroup.storageGroupFree;

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

        anvilFiles[fileUUID] = file;
      });

      reduceContainer.anvils.push({
        ...anvil,
        anvilTotalMemory: BigInt(anvilTotalMemory),
        anvilTotalAllocatedMemory: BigInt(anvilTotalAllocatedMemory),
        anvilTotalAvailableMemory: BigInt(anvilTotalAvailableMemory),
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
      });
      reduceContainer.anvilSelectItems.push({
        displayValue: anvilName,
        value: anvilUUID,
      });

      return reduceContainer;
    },
    {
      anvils: [],
      anvilSelectItems: [],
      files: [],
      fileSelectItems: [],
      storageGroups: [],
      storageGroupSelectItems: [],
      storageGroupUUIDMapToFree: {},
    },
  );

  Object.values(anvilFiles).forEach((distinctFile) => {
    result.files.push(distinctFile);
    result.fileSelectItems.push({
      displayValue: distinctFile.fileName,
      value: distinctFile.fileUUID,
    });
  });

  return result;
};
const dSize = (
  valueToFormat: FormatDataSizeInputValue,
  {
    fromUnit,
    onFailure,
    onSuccess,
    precision,
    toUnit,
  }: FormatDataSizeOptions & {
    onFailure?: (error?: unknown, value?: string, unit?: DataSizeUnit) => void;
    onSuccess?: {
      bigint?: (value: bigint, unit: DataSizeUnit) => void;
      number?: (value: number, unit: DataSizeUnit) => void;
      string?: (value: string, unit: DataSizeUnit) => void;
    };
  } = {},
) => {
  const formatted = baseDSize(valueToFormat, {
    fromUnit,
    precision,
    toUnit,
  });

  if (formatted) {
    const { value, unit } = formatted;

    try {
      onSuccess?.bigint?.call(null, BigInt(value), unit);
      onSuccess?.number?.call(null, parseFloat(value), unit);
      onSuccess?.string?.call(null, value, unit);
    } catch (convertValueToTypeError) {
      onFailure?.call(null, convertValueToTypeError, value, unit);
    }
  } else {
    onFailure?.call(null);
  }
};

const dSizeToBytes = (
  value: FormatDataSizeInputValue,
  fromUnit: DataSizeUnit,
  onSuccess: (newValue: bigint, unit: DataSizeUnit) => void,
  onFailure?: (
    error?: unknown,
    unchangedValue?: string,
    unit?: DataSizeUnit,
  ) => void,
) => {
  dSize(value, {
    fromUnit,
    onFailure,
    onSuccess: {
      bigint: onSuccess,
    },
    precision: 0,
    toUnit: 'B',
  });
};

const filterAnvils: FilterAnvilsFunction = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  storageGroupUUIDMapToFree: StorageGroupUUIDMapToFree,
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
                hasEnoughStorage = vdSize <= storageGroupUUIDMapToFree[uuid];
              }

              return hasStorageGroup && hasEnoughStorage;
            }),
          // Do storage groups on this anvil node pair have enough free space
          // to contain multiple VDs?
          () =>
            Object.entries(storageGroupTotals).every(([uuid, total]) =>
              uuid === 'all'
                ? total <= anvilStorageGroupFreeTotal
                : total <= storageGroupUUIDMapToFree[uuid],
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
      result.maxVirtualDiskSizes[uuidIndex] = storageGroupUUIDMapToFree[uuid];
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
  storageGroupUUIDMapToFree: StorageGroupUUIDMapToFree,
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

    dSizeToBytes(
      value,
      unit,
      (convertedVDSizeValue) => {
        set('sizes', convertedVDSizeValue);
        updateLimits({ virtualDisks });
      },
      () => {
        set('sizes', BIGINT_ZERO);
        updateLimits({ virtualDisks });
      },
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
      key={`ps-virtual-disk-${vdIndex}`}
      sx={{
        display: 'flex',
        flexDirection: 'column',

        '& > :not(:first-child)': {
          marginTop: '1em',
        },
      }}
    >
      <BodyText
        text={`Index: ${vdIndex}, Virtual disk size: ${get(
          'sizes',
        ).toString()}, Max: ${get('maxes').toString()}`}
      />
      {createOutlinedInputWithSelect(
        `ps-virtual-disk-size-${vdIndex}`,
        'Virtual disk size',
        DATA_SIZE_UNITS,
        {
          inputWithLabelProps: {
            inputProps: {
              onChange: ({ target: { value } }) => {
                handleVDSizeChange({ value });
              },
              type: 'number',
              value: get('inputSizes'),
            },
          },
          selectProps: {
            onChange: ({ target: { value } }) => {
              const selectedUnit = value as DataSizeUnit;

              handleVDSizeChange({ unit: selectedUnit });
            },
            value: get('inputUnits'),
          },
        },
      )}
      {createOutlinedSelect(
        `ps-storage-group-${vdIndex}`,
        'Storage group',
        storageGroupSelectItems,
        {
          disableItem: (value) =>
            !(
              includeStorageGroupUUIDs.includes(value) &&
              get('sizes') <= storageGroupUUIDMapToFree[value]
            ),
          selectProps: {
            onChange: ({ target: { value } }) => {
              const selectedStorageGroupUUID = value as string;

              handleVDStorageGroupChange(selectedStorageGroupUUID);
            },
            value: get('inputStorageGroupUUIDs'),
            onClearIndicatorClick: () => handleVDStorageGroupChange(''),
          },
        },
      )}
    </Box>
  );
};

const addVirtualDisk = ({
  existingVirtualDisks: virtualDisks = {
    maxes: [],
    inputMaxes: [],
    inputSizes: [],
    inputStorageGroupUUIDs: [],
    inputUnits: [],
    sizes: [],
  },
  max = BIGINT_ZERO,
  inputMax = '0',
  inputSize = '',
  inputStorageGroupUUID = '',
  inputUnit = 'B',
  setVirtualDisks,
  size = BIGINT_ZERO,
}: {
  existingVirtualDisks?: VirtualDiskStates;
  max?: bigint;
  inputMax?: string;
  inputSize?: string;
  inputStorageGroupUUID?: string;
  inputUnit?: DataSizeUnit;
  setVirtualDisks?: Dispatch<SetStateAction<VirtualDiskStates>>;
  size?: bigint;
} = {}) => {
  const {
    maxes,
    inputMaxes,
    inputSizes,
    inputStorageGroupUUIDs,
    inputUnits,
    sizes,
  } = virtualDisks;

  maxes.push(max);
  inputMaxes.push(inputMax);
  inputSizes.push(inputSize);
  inputStorageGroupUUIDs.push(inputStorageGroupUUID);
  inputUnits.push(inputUnit);
  sizes.push(size);

  setVirtualDisks?.call(null, { ...virtualDisks });

  return virtualDisks;
};

const filterBlanks: (array: string[]) => string[] = (array: string[]) =>
  array.filter((value) => value !== '');

const ProvisionServerDialog = ({
  dialogProps: { open },
}: ProvisionServerDialogProps): JSX.Element => {
  const [allAnvils, setAllAnvils] = useState<
    OrganizedAnvilDetailMetadataForProvisionServer[]
  >([]);
  const [storageGroupUUIDMapToFree, setStorageGroupUUIDMapToFree] =
    useState<StorageGroupUUIDMapToFree>({});

  const [anvilSelectItems, setAnvilSelectItems] = useState<SelectItem[]>([]);
  const [fileSelectItems, setFileSelectItems] = useState<SelectItem[]>([]);
  const [osAutocompleteOptions, setOSAutocompleteOptions] = useState<
    { label: string; key: string }[]
  >([]);
  const [storageGroupSelectItems, setStorageGroupSelectItems] = useState<
    SelectItem[]
  >([]);

  const [inputCPUCoresValue, setInputCPUCoresValue] = useState<number>(1);
  const [inputCPUCoresMax, setInputCPUCoresMax] = useState<number>(0);

  const [memory, setMemory] = useState<bigint>(BIGINT_ZERO);
  const [memoryMax, setMemoryMax] = useState<bigint>(BIGINT_ZERO);
  const [inputMemoryMax, setInputMemoryMax] = useState<string>('0');
  const [inputMemoryValue, setInputMemoryValue] = useState<string>('');
  const [inputMemoryUnit, setInputMemoryUnit] = useState<DataSizeUnit>('B');

  const [virtualDisks, setVirtualDisks] = useState<VirtualDiskStates>(
    addVirtualDisk(),
  );

  const [inputInstallISOFileUUID, setInputInstallISOFileUUID] =
    useState<string>('');
  const [inputDriverISOFileUUID, setInputDriverISOFileUUID] =
    useState<string>('');

  const [inputAnvilValue, setInputAnvilValue] = useState<string>('');

  const [includeAnvilUUIDs, setIncludeAnvilUUIDs] = useState<string[]>([]);
  const [includeFileUUIDs, setIncludeFileUUIDs] = useState<string[]>([]);
  const [includeStorageGroupUUIDs, setIncludeStorageGroupUUIDs] = useState<
    string[]
  >([]);

  const updateLimits: UpdateLimitsFunction = ({
    allAnvils: ulAllAnvils = allAnvils,
    cpuCores: ulCPUCores = inputCPUCoresValue,
    fileUUIDs: ulFileUUIDs = [inputInstallISOFileUUID, inputDriverISOFileUUID],
    includeAnvilUUIDs: ulIncludeAnvilUUIDs = filterBlanks([inputAnvilValue]),
    includeFileUUIDs: ulIncludeFileUUIDs,
    includeStorageGroupUUIDs: ulIncludeStorageGroupUUIDs,
    inputMemoryUnit: ulInputMemoryUnit = inputMemoryUnit,
    memory: ulMemory = memory,
    storageGroupUUIDMapToFree:
      ulStorageGroupUUIDMapToFree = storageGroupUUIDMapToFree,
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
      ulStorageGroupUUIDMapToFree,
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

    ulVirtualDisks.maxes = maxVirtualDiskSizes;
    setVirtualDisks({ ...ulVirtualDisks });

    setIncludeAnvilUUIDs(anvilUUIDs);
    setIncludeFileUUIDs(fileUUIDs);
    setIncludeStorageGroupUUIDs(storageGroupUUIDs);

    dSize(maxMemory, {
      fromUnit: 'B',
      onSuccess: {
        string: (value) => setInputMemoryMax(value),
      },
      toUnit: ulInputMemoryUnit,
    });
  };
  // The memorized version of updateLimits() should only be called during first render.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const initLimits = useCallback(updateLimits, []);

  const handleInputMemoryValueChange = ({
    value = inputMemoryValue,
    unit = inputMemoryUnit,
  }: {
    value?: string;
    unit?: DataSizeUnit;
  }) => {
    if (value !== inputMemoryValue) {
      setInputMemoryValue(value);
    }

    if (unit !== inputMemoryUnit) {
      setInputMemoryUnit(unit);
    }

    dSizeToBytes(
      value,
      unit,
      (convertedMemory) => {
        setMemory(convertedMemory);

        updateLimits({
          memory: convertedMemory,
        });
      },
      () =>
        updateLimits({
          memory: BIGINT_ZERO,
        }),
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
      fileSelectItems: ueFileSelectItems,
      storageGroupSelectItems: ueStorageGroupSelectItems,
      storageGroupUUIDMapToFree: ueStorageGroupUUIDMapToFree,
    } = organizeAnvils(data.anvils);

    setAllAnvils(ueAllAnvils);
    setStorageGroupUUIDMapToFree(ueStorageGroupUUIDMapToFree);

    setAnvilSelectItems(ueAnvilSelectItems);
    setFileSelectItems(ueFileSelectItems);
    setStorageGroupSelectItems(ueStorageGroupSelectItems);

    initLimits({
      allAnvils: ueAllAnvils,
      storageGroupUUIDMapToFree: ueStorageGroupUUIDMapToFree,
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
          paddingTop: '.6em',

          '& > :not(:first-child)': {
            marginTop: '1em',
          },
        }}
      >
        <OutlinedInputWithLabel id="ps-server-name" label="Server name" />
        {createOutlinedSlider('ps-cpu-cores', 'CPU cores', inputCPUCoresValue, {
          sliderProps: {
            onChange: (value) => {
              const newCPUCoresValue = value as number;

              if (newCPUCoresValue !== inputCPUCoresValue) {
                setInputCPUCoresValue(newCPUCoresValue);

                updateLimits({
                  cpuCores: newCPUCoresValue,
                });
              }
            },
            max: inputCPUCoresMax,
            min: 1,
          },
        })}
        <BodyText
          text={`Memory: ${memory.toString()}, Max: ${memoryMax.toString()}`}
        />
        {createOutlinedInputWithSelect('ps-memory', 'Memory', DATA_SIZE_UNITS, {
          inputWithLabelProps: {
            inputProps: {
              endAdornment: (
                <ContainedButton
                  onClick={() =>
                    handleInputMemoryValueChange({ value: inputMemoryMax })
                  }
                  sx={{
                    marginLeft: '14px',
                    minWidth: 'unset',
                    whiteSpace: 'nowrap',
                  }}
                >{`Max: ${inputMemoryMax} ${inputMemoryUnit}`}</ContainedButton>
              ),
              onChange: ({ target: { value } }) => {
                handleInputMemoryValueChange({ value });
              },
              type: 'number',
              value: inputMemoryValue,
            },
          },
          selectProps: {
            onChange: ({ target: { value } }) => {
              const selectedUnit = value as DataSizeUnit;

              handleInputMemoryValueChange({ unit: selectedUnit });
            },
            value: inputMemoryUnit,
          },
        })}
        {virtualDisks.maxes.map((max, vdIndex) =>
          createVirtualDiskForm(
            virtualDisks,
            vdIndex,
            setVirtualDisks,
            storageGroupSelectItems,
            includeStorageGroupUUIDs,
            updateLimits,
            storageGroupUUIDMapToFree,
          ),
        )}
        {createOutlinedSelect(
          'ps-install-image',
          'Install ISO',
          fileSelectItems,
          {
            hideItem: (value) => !includeFileUUIDs.includes(value),
            selectProps: {
              onChange: ({ target: { value } }) => {
                const newInstallISOFileUUID = value as string;

                handleInputInstallISOFileUUIDChange(newInstallISOFileUUID);
              },
              onClearIndicatorClick: () =>
                handleInputInstallISOFileUUIDChange(''),
              value: inputInstallISOFileUUID,
            },
          },
        )}
        {createOutlinedSelect(
          'ps-driver-image',
          'Driver ISO',
          fileSelectItems,
          {
            hideItem: (value) => !includeFileUUIDs.includes(value),
            selectProps: {
              onChange: ({ target: { value } }) => {
                const newDriverISOFileUUID = value as string;

                handleInputDriverISOFileUUIDChange(newDriverISOFileUUID);
              },
              onClearIndicatorClick: () =>
                handleInputDriverISOFileUUIDChange(''),
              value: inputDriverISOFileUUID,
            },
          },
        )}
        {createOutlinedSelect('ps-anvil', 'Anvil', anvilSelectItems, {
          disableItem: (value) => !includeAnvilUUIDs.includes(value),
          selectProps: {
            onChange: ({ target: { value } }) => {
              const newAnvilUUID: string = value as string;

              handleInputAnvilValueChange(newAnvilUUID);
            },
            onClearIndicatorClick: () => handleInputAnvilValueChange(''),
            value: inputAnvilValue,
          },
        })}
        <Autocomplete
          id="ps-optimize-for-os"
          label="Optimize for OS"
          noOptionsText="No matching OS"
          openOnFocus
          options={osAutocompleteOptions}
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
        <ContainedButton>Provision</ContainedButton>
      </Box>
    </Dialog>
  );
};

export default ProvisionServerDialog;
