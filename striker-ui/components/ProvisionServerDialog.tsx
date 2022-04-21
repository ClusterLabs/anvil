import { useEffect, useState } from 'react';
import {
  Checkbox,
  Dialog,
  DialogProps,
  FormControl,
  FormGroup,
} from '@mui/material';
import {
  dSize as baseDSize,
  DataSizeUnit,
  FormatDataSizeOptions,
  FormatDataSizeInputValue,
} from 'format-data-size';

import MenuItem from './MenuItem';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel from './OutlinedInputLabel';
import { Panel, PanelHeader } from './Panels';
import Select, { SelectProps } from './Select';
import Slider, { SliderProps } from './Slider';
import { BodyText, HeaderText } from './Text';
import ContainedButton from './ContainedButton';

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

const createOutlinedInput = (
  id: string,
  label: string,
  inputProps?: Partial<OutlinedInputProps>,
): JSX.Element => (
  <FormControl>
    <OutlinedInputLabel {...{ htmlFor: id }}>{label}</OutlinedInputLabel>
    {/* eslint-disable-next-line react/jsx-props-no-spreading */}
    <OutlinedInput {...{ id, label, ...inputProps }} />
  </FormControl>
);

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
    inputProps,
    selectProps,
  }: {
    inputProps?: Partial<OutlinedInputProps>;
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
    {createOutlinedInput(id, label, inputProps)}
    {createOutlinedSelect(`${id}-nested-select`, undefined, selectItems, {
      selectProps,
    })}
  </FormControl>
);

const organizeAnvils = (
  data: AnvilDetailMetadataForProvisionServer[],
): OrganizedAnvilDetailMetadataForProvisionServer[] =>
  data.map((anvil) => {
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

    const { storageGroupUUIDs, organizedStorageGroups } = storageGroups.reduce<{
      storageGroupUUIDs: string[];
      organizedStorageGroups: OrganizedStorageGroupMetadataForProvisionServer[];
    }>(
      (reduced, storageGroup) => {
        reduced.storageGroupUUIDs.push(storageGroup.storageGroupUUID);
        reduced.organizedStorageGroups.push({
          ...storageGroup,
          anvilUUID,
          anvilName,
          storageGroupSize: BigInt(storageGroup.storageGroupSize),
          storageGroupFree: BigInt(storageGroup.storageGroupFree),
        });

        return reduced;
      },
      {
        storageGroupUUIDs: [],
        organizedStorageGroups: [],
      },
    );

    const fileUUIDs = files.map(({ fileUUID }) => fileUUID);

    return {
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
      storageGroupUUIDs,
      storageGroups: organizedStorageGroups,
      fileUUIDs,
    };
  });

const organizeStorageGroups = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
) =>
  organizedAnvils.reduce<OrganizedStorageGroupMetadataForProvisionServer[]>(
    (reducedStorageGroups, { storageGroups }) => {
      reducedStorageGroups.push(...storageGroups);

      return reducedStorageGroups;
    },
    [],
  );

const organizeFiles = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
) =>
  organizedAnvils.reduce<FileMetadataForProvisionServer[]>(
    (reducedFiles, { files }) => {
      files.forEach((file) => {
        // Avoid pushing duplicate file UUIDs.
        if (
          reducedFiles.find(({ fileUUID }) => file.fileUUID === fileUUID) ===
          undefined
        ) {
          reducedFiles.push(file);
        }
      });

      return reducedFiles;
    },
    [],
  );

const getMaxAvailableValues = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  {
    includeAnvilUUIDs,
    includeStorageGroupUUIDs,
  }: {
    includeAnvilUUIDs?: string[];
    includeStorageGroupUUIDs?: string[];
  } = {},
) => {
  let testIncludeAnvil: (uuid: string) => boolean = () => true;
  let testIncludeStorageGroup: (uuid: string) => boolean = () => true;

  if (includeAnvilUUIDs && includeAnvilUUIDs.length > 0) {
    testIncludeAnvil = (uuid: string) => includeAnvilUUIDs.includes(uuid);
  }

  if (includeStorageGroupUUIDs && includeStorageGroupUUIDs.length > 0) {
    testIncludeStorageGroup = (uuid: string) =>
      includeStorageGroupUUIDs.includes(uuid);
  }

  return organizedAnvils.reduce<{
    maxCPUCores: number;
    maxMemory: bigint;
    maxVirtualDiskSize: bigint;
  }>(
    (
      reducedValues,
      {
        anvilUUID,
        anvilTotalCPUCores,
        anvilTotalAvailableMemory,
        storageGroups,
      },
    ) => {
      if (testIncludeAnvil(anvilUUID)) {
        reducedValues.maxCPUCores = Math.max(
          anvilTotalCPUCores,
          reducedValues.maxCPUCores,
        );

        if (anvilTotalAvailableMemory > reducedValues.maxMemory) {
          reducedValues.maxMemory = anvilTotalAvailableMemory;
        }

        storageGroups.forEach(({ storageGroupUUID, storageGroupFree }) => {
          if (
            testIncludeStorageGroup(storageGroupUUID) &&
            storageGroupFree > reducedValues.maxVirtualDiskSize
          ) {
            reducedValues.maxVirtualDiskSize = storageGroupFree;
          }
        });
      }

      return reducedValues;
    },
    {
      maxCPUCores: 0,
      maxMemory: BIGINT_ZERO,
      maxVirtualDiskSize: BIGINT_ZERO,
    },
  );
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

const filterAnvils = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  cpuCores: number,
  memory: bigint,
  selectedStorageGroupUUID: string | undefined,
) =>
  organizedAnvils.filter(
    ({ anvilTotalCPUCores, anvilTotalAvailableMemory, storageGroups }) => {
      const isEnoughCPUCores = cpuCores <= anvilTotalCPUCores;
      const isEnoughMemory = memory <= anvilTotalAvailableMemory;
      const hasSelectedStorageGroup =
        storageGroups.find(
          ({ storageGroupUUID }) =>
            storageGroupUUID === selectedStorageGroupUUID,
        ) !== undefined;

      return isEnoughCPUCores && isEnoughMemory && hasSelectedStorageGroup;
    },
  );

const filterStorageGroups = (
  organizedStorageGroups: OrganizedStorageGroupMetadataForProvisionServer[],
  virtualDiskSize: bigint,
  includeUUIDs?: string[],
) => {
  let testInclude: (uuid: string) => boolean = () => true;

  if (includeUUIDs && includeUUIDs.length > 0) {
    testInclude = (uuid: string) => includeUUIDs.includes(uuid);
  }

  return organizedStorageGroups.filter(
    ({ storageGroupUUID, storageGroupFree }) => {
      const isEnoughStorage = virtualDiskSize <= storageGroupFree;
      const isIncluded = testInclude(storageGroupUUID);

      return isEnoughStorage && isIncluded;
    },
  );
};

const ProvisionServerDialog = ({
  dialogProps: { open },
}: ProvisionServerDialogProps): JSX.Element => {
  const [cpuCoresValue, setCPUCoresValue] = useState<number>(1);
  const [inputCPUCoresMax, setInputCPUCoresMax] = useState<number>(0);

  const [memoryValue, setMemoryValue] = useState<bigint>(BIGINT_ZERO);
  const [inputMemoryMax, setInputMemoryMax] = useState<bigint>(BIGINT_ZERO);
  const [inputMemoryValue, setInputMemoryValue] = useState<string>('');
  const [inputMemoryUnit, setInputMemoryUnit] = useState<DataSizeUnit>('B');

  const [virtualDiskSizeValue, setVirtualDiskSizeValue] =
    useState<bigint>(BIGINT_ZERO);
  const [inputVirtualDiskSizeMax, setInputVirtualDiskSizeMax] =
    useState<bigint>(BIGINT_ZERO);
  const [inputVirtualDiskSizeValue, setInputVirtualDiskSizeValue] =
    useState<string>('');
  const [inputVirtualDiskSizeUnit, setInputVirtualDiskSizeUnit] =
    useState<DataSizeUnit>('B');

  const [storageGroupValue, setStorageGroupValue] = useState<string[]>([]);
  const [excludedStorageGroupUUIDs, setExcludedStorageGroupUUIDs] = useState<
    string[]
  >([]);
  const [selectedStorageGroupUUID, setSelectedStorageGroupUUID] = useState<
    string | undefined
  >();

  const [installISOFileUUID, setInstallISOFileUUID] = useState<string>('');
  const [driverISOFileUUID, setDriverISOFileUUID] = useState<string>('');
  const [excludedFileUUIDs, setExcludedFileUUIDs] = useState<string[]>([]);

  const [anvilValue, setAnvilValue] = useState<string[]>([]);
  const [selectedAnvilUUID, setSelectedAnvilUUID] = useState<
    string | undefined
  >();

  const data = MOCK_DATA;

  const organizedAnvils = organizeAnvils(data.anvils);
  const organizedStorageGroups = organizeStorageGroups(organizedAnvils);
  const organizedFiles = organizeFiles(organizedAnvils);

  const { maxCPUCores, maxMemory, maxVirtualDiskSize } =
    getMaxAvailableValues(organizedAnvils);

  const selectFiles = organizedFiles.map(({ fileUUID, fileName }) => ({
    displayValue: fileName,
    value: fileUUID,
  }));

  // const optimizeOSList = data.osList.map((keyValuePair) =>
  //   keyValuePair.split(','),
  // );

  useEffect(() => {
    setInputCPUCoresMax(maxCPUCores);
    setInputMemoryMax(maxMemory);
    setInputVirtualDiskSizeMax(maxVirtualDiskSize);
  }, [maxCPUCores, maxMemory, maxVirtualDiskSize]);

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
      <FormGroup>
        {createOutlinedInput('ps-server-name', 'Server name')}
        {createOutlinedSlider('ps-cpu-cores', 'CPU cores', cpuCoresValue, {
          sliderProps: {
            onChange: (value) => {
              setCPUCoresValue(value as number);
            },
            max: inputCPUCoresMax,
            min: 1,
          },
        })}
        <BodyText
          text={`Memory: ${memoryValue.toString()}, Max: ${inputMemoryMax.toString()}`}
        />
        {createOutlinedInputWithSelect('ps-memory', 'Memory', DATA_SIZE_UNITS, {
          inputProps: {
            type: 'number',
            onChange: ({ target: { value } }) => {
              setInputMemoryValue(value);

              dSize(value, {
                fromUnit: inputMemoryUnit,
                onSuccess: {
                  bigint: (newValue) => {
                    setMemoryValue(newValue);
                  },
                },
                precision: 0,
                toUnit: 'B',
              });
            },
            value: inputMemoryValue,
          },
          selectProps: {
            onChange: ({ target: { value } }) => {
              const selectedUnit = value as DataSizeUnit;

              setInputMemoryUnit(selectedUnit);

              dSize(inputMemoryValue, {
                fromUnit: selectedUnit,
                onSuccess: {
                  bigint: (newValue) => {
                    setMemoryValue(newValue);
                  },
                },
                precision: 0,
                toUnit: 'B',
              });
            },
            value: inputMemoryUnit,
          },
        })}
        <BodyText
          text={`Virtual disk size: ${virtualDiskSizeValue.toString()}, Max: ${inputVirtualDiskSizeMax.toString()}`}
        />
        {createOutlinedInputWithSelect(
          'ps-virtual-disk-size',
          'Virtual disk size',
          DATA_SIZE_UNITS,
          {
            inputProps: {
              type: 'number',
              onChange: ({ target: { value } }) => {
                setInputVirtualDiskSizeValue(value);

                dSize(value, {
                  fromUnit: inputVirtualDiskSizeUnit,
                  onSuccess: {
                    bigint: (newValue) => {
                      setVirtualDiskSizeValue(newValue);
                    },
                  },
                  precision: 0,
                  toUnit: 'B',
                });
              },
              value: inputVirtualDiskSizeValue,
            },
            selectProps: {
              onChange: ({ target: { value } }) => {
                const selectedUnit = value as DataSizeUnit;

                setInputVirtualDiskSizeUnit(selectedUnit);

                dSize(inputVirtualDiskSizeValue, {
                  fromUnit: selectedUnit,
                  onSuccess: {
                    bigint: (newValue) => {
                      setVirtualDiskSizeValue(newValue);
                    },
                  },
                  precision: 0,
                  toUnit: 'B',
                });
              },
              value: inputVirtualDiskSizeUnit,
            },
          },
        )}
        <BodyText
          text={`Selected storage group UUID: ${selectedStorageGroupUUID}`}
        />
        {createOutlinedSelect(
          'ps-storage-group',
          'Storage group',
          organizedStorageGroups.map(
            ({ anvilName, storageGroupUUID, storageGroupName }) => ({
              displayValue: `${anvilName} -- ${storageGroupName}`,
              value: storageGroupUUID,
            }),
          ),
          {
            checkItem: (value) => storageGroupValue.includes(value),
            hideItem: (value) => excludedStorageGroupUUIDs.includes(value),
            selectProps: {
              multiple: true,
              onChange: ({ target: { value } }) => {
                const subsetStorageGroupsUUID: string[] =
                  typeof value === 'string'
                    ? value.split(',')
                    : (value as string[]);

                setStorageGroupValue(subsetStorageGroupsUUID);

                setSelectedStorageGroupUUID(
                  filterStorageGroups(
                    organizedStorageGroups,
                    virtualDiskSizeValue,
                    subsetStorageGroupsUUID,
                  )[0]?.storageGroupUUID,
                );

                setInputVirtualDiskSizeMax(
                  getMaxAvailableValues(organizedAnvils, {
                    includeAnvilUUIDs: anvilValue,
                    includeStorageGroupUUIDs: subsetStorageGroupsUUID,
                  }).maxVirtualDiskSize,
                );
              },
              value: storageGroupValue,
            },
          },
        )}
        {createOutlinedSelect('ps-install-image', 'Install ISO', selectFiles, {
          hideItem: (value) => excludedFileUUIDs.includes(value),
          selectProps: {
            onChange: ({ target: { value } }) => {
              setInstallISOFileUUID(value as string);
            },
            value: installISOFileUUID,
          },
        })}
        {createOutlinedSelect('ps-driver-image', 'Driver ISO', selectFiles, {
          hideItem: (value) => excludedFileUUIDs.includes(value),
          selectProps: {
            onChange: ({ target: { value } }) => {
              setDriverISOFileUUID(value as string);
            },
            value: driverISOFileUUID,
          },
        })}
        <BodyText text={`Selected anvil UUID: ${selectedAnvilUUID}`} />
        {createOutlinedSelect(
          'ps-anvil',
          'Anvil',
          organizedAnvils.map(({ anvilUUID, anvilName }) => ({
            displayValue: anvilName,
            value: anvilUUID,
          })),
          {
            checkItem: (value) => anvilValue.includes(value),
            selectProps: {
              multiple: true,
              onChange: ({ target: { value } }) => {
                const subsetAnvilUUIDs: string[] =
                  typeof value === 'string'
                    ? value.split(',')
                    : (value as string[]);

                setAnvilValue(subsetAnvilUUIDs);

                const includedFileUUIDs: string[] = [];

                let newExcludedStorageGroupUUIDs: string[] = [];
                let newExcludedFileUUIDs: string[] = [];

                if (subsetAnvilUUIDs.length > 0) {
                  ({ newExcludedStorageGroupUUIDs, newExcludedFileUUIDs } =
                    organizedAnvils.reduce<{
                      newExcludedStorageGroupUUIDs: string[];
                      newExcludedFileUUIDs: string[];
                    }>(
                      (
                        reduced,
                        { anvilUUID, storageGroupUUIDs, fileUUIDs },
                      ) => {
                        if (subsetAnvilUUIDs.includes(anvilUUID)) {
                          includedFileUUIDs.push(...fileUUIDs);
                        } else {
                          reduced.newExcludedStorageGroupUUIDs.push(
                            ...storageGroupUUIDs,
                          );
                          reduced.newExcludedFileUUIDs.push(...fileUUIDs);
                        }

                        return reduced;
                      },
                      {
                        newExcludedStorageGroupUUIDs: [],
                        newExcludedFileUUIDs: [],
                      },
                    ));

                  includedFileUUIDs.forEach((fileUUID) => {
                    newExcludedFileUUIDs.splice(
                      newExcludedFileUUIDs.indexOf(fileUUID),
                      1,
                    );
                  });
                }

                setExcludedStorageGroupUUIDs(newExcludedStorageGroupUUIDs);
                setExcludedFileUUIDs(newExcludedFileUUIDs);

                const newStorageGroupValue = storageGroupValue.filter(
                  (uuid) => !newExcludedStorageGroupUUIDs.includes(uuid),
                );
                setStorageGroupValue(newStorageGroupValue);

                newExcludedFileUUIDs.forEach((excludedFileUUID) => {
                  if (installISOFileUUID === excludedFileUUID) {
                    setInstallISOFileUUID('');
                  }

                  if (driverISOFileUUID === excludedFileUUID) {
                    setDriverISOFileUUID('');
                  }
                });

                const {
                  maxCPUCores: localMaxCPUCores,
                  maxMemory: localMaxMemory,
                  maxVirtualDiskSize: localMaxVDSize,
                } = getMaxAvailableValues(organizedAnvils, {
                  includeAnvilUUIDs: subsetAnvilUUIDs,
                  includeStorageGroupUUIDs: newStorageGroupValue,
                });

                setInputCPUCoresMax(localMaxCPUCores);
                setInputMemoryMax(localMaxMemory);
                setInputVirtualDiskSizeMax(localMaxVDSize);

                setCPUCoresValue(Math.min(cpuCoresValue, localMaxCPUCores));

                setSelectedAnvilUUID(
                  filterAnvils(
                    organizedAnvils,
                    cpuCoresValue,
                    memoryValue,
                    selectedStorageGroupUUID,
                  )[0]?.anvilUUID,
                );
              },
              value: anvilValue,
            },
          },
        )}
        {/*
        {createOutlinedSelect(
          'ps-optimize-for-os',
          'Optimize for OS',
          optimizeOSList,
        )} */}
      </FormGroup>
      <ContainedButton>Provision</ContainedButton>
    </Dialog>
  );
};

export default ProvisionServerDialog;
