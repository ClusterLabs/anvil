import { useCallback, useEffect, useState } from 'react';
import { Box, Checkbox, Dialog, DialogProps, FormControl } from '@mui/material';
import {
  dSize as baseDSize,
  DataSizeUnit,
  FormatDataSizeOptions,
  FormatDataSizeInputValue,
} from 'format-data-size';

import Autocomplete from './Autocomplete';
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

      const { storageGroupUUIDs, anvilStorageGroups } = storageGroups.reduce<{
        storageGroupUUIDs: string[];
        anvilStorageGroups: OrganizedStorageGroupMetadataForProvisionServer[];
      }>(
        (reducedStorageGroups, storageGroup) => {
          const anvilStorageGroup = {
            ...storageGroup,
            anvilUUID,
            anvilName,
            storageGroupSize: BigInt(storageGroup.storageGroupSize),
            storageGroupFree: BigInt(storageGroup.storageGroupFree),
          };

          reducedStorageGroups.storageGroupUUIDs.push(
            storageGroup.storageGroupUUID,
          );
          reducedStorageGroups.anvilStorageGroups.push(anvilStorageGroup);

          reduceContainer.storageGroups.push(anvilStorageGroup);
          reduceContainer.storageGroupSelectItems.push({
            displayValue: `${anvilName} -- ${storageGroup.storageGroupName}`,
            value: storageGroup.storageGroupUUID,
          });

          return reducedStorageGroups;
        },
        {
          storageGroupUUIDs: [],
          anvilStorageGroups: [],
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
        storageGroupUUIDs,
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

const filterAnvils = (
  organizedAnvils: OrganizedAnvilDetailMetadataForProvisionServer[],
  cpuCores: number,
  memory: bigint,
  fileUUIDs: string[],
  {
    includeAnvilUUIDs = [],
    includeStorageGroupUUIDs = [],
  }: {
    includeAnvilUUIDs?: string[];
    includeStorageGroupUUIDs?: string[];
  } = {},
) => {
  let testIncludeAnvil: (uuid: string) => boolean = () => true;
  let testIncludeStorageGroup: (uuid: string) => boolean = () => true;

  if (includeAnvilUUIDs.length > 0) {
    testIncludeAnvil = (uuid: string) => includeAnvilUUIDs.includes(uuid);
  }

  if (includeStorageGroupUUIDs.length > 0) {
    testIncludeStorageGroup = (uuid: string) =>
      includeStorageGroupUUIDs.includes(uuid);
  }

  return organizedAnvils.reduce<{
    anvils: OrganizedAnvilDetailMetadataForProvisionServer[];
    anvilUUIDs: string[];
    fileUUIDs: string[];
    maxCPUCores: number;
    maxMemory: bigint;
    maxVirtualDiskSize: bigint;
    storageGroupUUIDs: string[];
  }>(
    (result, organizedAnvil) => {
      const { anvilUUID } = organizedAnvil;

      if (testIncludeAnvil(anvilUUID)) {
        const {
          anvilTotalCPUCores,
          anvilTotalAvailableMemory,
          files,
          fileUUIDs: localFileUUIDs,
          storageGroups,
        } = organizedAnvil;

        const usableConditions: boolean[] = [
          cpuCores <= anvilTotalCPUCores,
          memory <= anvilTotalAvailableMemory,
          fileUUIDs.reduce<boolean>(
            (localHasFiles, fileUUID) =>
              fileUUID === ''
                ? localHasFiles
                : localHasFiles && localFileUUIDs.includes(fileUUID),
            true,
          ),
          storageGroups.length > 0,
        ];

        if (!usableConditions.includes(false)) {
          result.anvils.push(organizedAnvil);
          result.anvilUUIDs.push(anvilUUID);

          result.maxCPUCores = Math.max(anvilTotalCPUCores, result.maxCPUCores);

          if (anvilTotalAvailableMemory > result.maxMemory) {
            result.maxMemory = anvilTotalAvailableMemory;
          }

          files.forEach(({ fileUUID }) => {
            if (!result.fileUUIDs.includes(fileUUID)) {
              result.fileUUIDs.push(fileUUID);
            }
          });

          storageGroups.forEach(({ storageGroupUUID, storageGroupFree }) => {
            if (
              testIncludeStorageGroup(storageGroupUUID) &&
              storageGroupFree > result.maxVirtualDiskSize
            ) {
              result.storageGroupUUIDs.push(storageGroupUUID);

              result.maxVirtualDiskSize = storageGroupFree;
            }
          });
        }
      }

      return result;
    },
    {
      anvils: [],
      anvilUUIDs: [],
      fileUUIDs: [],
      maxCPUCores: 0,
      maxMemory: BIGINT_ZERO,
      maxVirtualDiskSize: BIGINT_ZERO,
      storageGroupUUIDs: [],
    },
  );
};

type FilterAnvilsParameters = Parameters<typeof filterAnvils>;

const convertSelectValueToArray = (value: unknown) =>
  typeof value === 'string' ? value.split(',') : (value as string[]);

const ProvisionServerDialog = ({
  dialogProps: { open },
}: ProvisionServerDialogProps): JSX.Element => {
  const [allAnvils, setAllAnvils] = useState<
    OrganizedAnvilDetailMetadataForProvisionServer[]
  >([]);

  const [anvilSelectItems, setAnvilSelectItems] = useState<SelectItem[]>([]);
  const [fileSelectItems, setFileSelectItems] = useState<SelectItem[]>([]);
  const [osAutocompleteOptions, setOSAutocompleteOptions] = useState<
    { label: string; key: string }[]
  >([]);
  const [storageGroupSelectItems, setStorageGroupSelectItems] = useState<
    SelectItem[]
  >([]);

  const [cpuCoresValue, setCPUCoresValue] = useState<number>(1);
  const [inputCPUCoresMax, setInputCPUCoresMax] = useState<number>(0);

  const [memoryValue, setMemoryValue] = useState<bigint>(BIGINT_ZERO);
  const [memoryValueMax, setMemoryValueMax] = useState<bigint>(BIGINT_ZERO);
  const [inputMemoryMax, setInputMemoryMax] = useState<string>('0');
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
  const [includeStorageGroupUUIDs, setIncludeStorageGroupUUIDs] = useState<
    string[]
  >([]);

  const [installISOFileUUID, setInstallISOFileUUID] = useState<string>('');
  const [driverISOFileUUID, setDriverISOFileUUID] = useState<string>('');
  const [includeFileUUIDs, setIncludeFileUUIDs] = useState<string[]>([]);

  const [anvilValue, setAnvilValue] = useState<string[]>([]);
  const [includeAnvilUUIDs, setIncludeAnvilUUIDs] = useState<string[]>([]);

  const updateLimits = (
    filterArgs: FilterAnvilsParameters,
    {
      newInputMemoryUnit = inputMemoryUnit,
    }: { newInputMemoryUnit?: DataSizeUnit } = {},
  ) => {
    const {
      anvilUUIDs,
      fileUUIDs,
      maxCPUCores,
      maxMemory,
      maxVirtualDiskSize,
      storageGroupUUIDs,
    } = filterAnvils(...filterArgs);

    setInputCPUCoresMax(maxCPUCores);
    setMemoryValueMax(maxMemory);
    setInputVirtualDiskSizeMax(maxVirtualDiskSize);

    setIncludeAnvilUUIDs(anvilUUIDs);
    setIncludeFileUUIDs(fileUUIDs);
    setIncludeStorageGroupUUIDs(storageGroupUUIDs);

    dSize(maxMemory, {
      fromUnit: 'B',
      onSuccess: {
        string: (value) => setInputMemoryMax(value),
      },
      toUnit: newInputMemoryUnit,
    });
  };

  const memorizedUpdateLimit = useCallback(updateLimits, [inputMemoryUnit]);

  const handleInputMemoryValueChange = (value: string) => {
    setInputMemoryValue(value);

    const filterArgs: FilterAnvilsParameters = [
      allAnvils,
      cpuCoresValue,
      BIGINT_ZERO,
      [installISOFileUUID, driverISOFileUUID],
    ];

    dSizeToBytes(
      value,
      inputMemoryUnit,
      (convertedMemoryValue) => {
        setMemoryValue(convertedMemoryValue);

        filterArgs[2] = convertedMemoryValue;
        updateLimits(filterArgs);
      },
      () => updateLimits(filterArgs),
    );
  };

  useEffect(() => {
    const data = MOCK_DATA;

    const {
      anvils: localAllAnvils,
      anvilSelectItems: localAnvilSelectItems,
      fileSelectItems: localFileSelectItems,
      storageGroupSelectItems: localStorageGroupSelectItems,
    } = organizeAnvils(data.anvils);

    setAllAnvils(localAllAnvils);

    setAnvilSelectItems(localAnvilSelectItems);
    setFileSelectItems(localFileSelectItems);
    setStorageGroupSelectItems(localStorageGroupSelectItems);

    memorizedUpdateLimit([localAllAnvils, 0, BIGINT_ZERO, []]);

    setOSAutocompleteOptions(
      data.osList.map((keyValuePair) => {
        const [osKey, osValue] = keyValuePair.split(',');

        return {
          label: osValue,
          key: osKey,
        };
      }),
    );
  }, [memorizedUpdateLimit]);

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
        {createOutlinedSlider('ps-cpu-cores', 'CPU cores', cpuCoresValue, {
          sliderProps: {
            onChange: (value) => {
              const newCPUCoresValue = value as number;

              setCPUCoresValue(newCPUCoresValue);

              updateLimits([
                allAnvils,
                newCPUCoresValue,
                memoryValue,
                [installISOFileUUID, driverISOFileUUID],
              ]);
            },
            max: inputCPUCoresMax,
            min: 1,
          },
        })}
        <BodyText
          text={`Memory: ${memoryValue.toString()}, Max: ${memoryValueMax.toString()}`}
        />
        {createOutlinedInputWithSelect('ps-memory', 'Memory', DATA_SIZE_UNITS, {
          inputWithLabelProps: {
            inputProps: {
              endAdornment: (
                <ContainedButton
                  onClick={() => handleInputMemoryValueChange(inputMemoryMax)}
                  sx={{
                    marginLeft: '14px',
                    minWidth: 'unset',
                    whiteSpace: 'nowrap',
                  }}
                >{`Max: ${inputMemoryMax} ${inputMemoryUnit}`}</ContainedButton>
              ),
              onChange: ({ target: { value } }) => {
                handleInputMemoryValueChange(value);
              },
              type: 'number',
              value: inputMemoryValue,
            },
          },
          selectProps: {
            onChange: ({ target: { value } }) => {
              const selectedUnit = value as DataSizeUnit;

              setInputMemoryUnit(selectedUnit);

              const filterArgs: FilterAnvilsParameters = [
                allAnvils,
                cpuCoresValue,
                BIGINT_ZERO,
                [installISOFileUUID, driverISOFileUUID],
              ];

              dSizeToBytes(
                inputMemoryValue,
                selectedUnit,
                (convertedMemoryValue) => {
                  setMemoryValue(convertedMemoryValue);

                  filterArgs[2] = convertedMemoryValue;
                  updateLimits(filterArgs, {
                    newInputMemoryUnit: selectedUnit,
                  });
                },
                () =>
                  updateLimits(filterArgs, {
                    newInputMemoryUnit: selectedUnit,
                  }),
              );
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
            inputWithLabelProps: {
              inputProps: {
                onChange: ({ target: { value } }) => {
                  setInputVirtualDiskSizeValue(value);

                  dSizeToBytes(
                    value,
                    inputVirtualDiskSizeUnit,
                    setVirtualDiskSizeValue,
                  );
                },
                type: 'number',
                value: inputVirtualDiskSizeValue,
              },
            },
            selectProps: {
              onChange: ({ target: { value } }) => {
                const selectedUnit = value as DataSizeUnit;

                setInputVirtualDiskSizeUnit(selectedUnit);

                dSizeToBytes(
                  inputVirtualDiskSizeValue,
                  selectedUnit,
                  setVirtualDiskSizeValue,
                );
              },
              value: inputVirtualDiskSizeUnit,
            },
          },
        )}
        {createOutlinedSelect(
          'ps-storage-group',
          'Storage group',
          storageGroupSelectItems,
          {
            checkItem: (value) => storageGroupValue.includes(value),
            hideItem: (value) => !includeStorageGroupUUIDs.includes(value),
            selectProps: {
              multiple: true,
              onChange: ({ target: { value } }) => {
                const subsetStorageGroupsUUID: string[] =
                  convertSelectValueToArray(value);

                setStorageGroupValue(subsetStorageGroupsUUID);
              },
              value: storageGroupValue,
            },
          },
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

                setInstallISOFileUUID(newInstallISOFileUUID);

                updateLimits([
                  allAnvils,
                  cpuCoresValue,
                  memoryValue,
                  [newInstallISOFileUUID, driverISOFileUUID],
                ]);
              },
              value: installISOFileUUID,
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

                setDriverISOFileUUID(newDriverISOFileUUID);

                updateLimits([
                  allAnvils,
                  cpuCoresValue,
                  memoryValue,
                  [installISOFileUUID, newDriverISOFileUUID],
                ]);
              },
              value: driverISOFileUUID,
            },
          },
        )}
        {createOutlinedSelect('ps-anvil', 'Anvil', anvilSelectItems, {
          checkItem: (value) => anvilValue.includes(value),
          disableItem: (value) => !includeAnvilUUIDs.includes(value),
          selectProps: {
            multiple: true,
            onChange: ({ target: { value } }) => {
              const subsetAnvilUUIDs: string[] =
                convertSelectValueToArray(value);

              setAnvilValue(subsetAnvilUUIDs);

              // const includedFileUUIDs: string[] = [];

              // let newExcludedStorageGroupUUIDs: string[] = [];
              // let newExcludedFileUUIDs: string[] = [];

              // if (subsetAnvilUUIDs.length > 0) {
              //   ({ newExcludedStorageGroupUUIDs, newExcludedFileUUIDs } =
              //     organizedAnvils.reduce<{
              //       newExcludedStorageGroupUUIDs: string[];
              //       newExcludedFileUUIDs: string[];
              //     }>(
              //       (reduced, { anvilUUID, storageGroupUUIDs, fileUUIDs }) => {
              //         if (subsetAnvilUUIDs.includes(anvilUUID)) {
              //           includedFileUUIDs.push(...fileUUIDs);
              //         } else {
              //           reduced.newExcludedStorageGroupUUIDs.push(
              //             ...storageGroupUUIDs,
              //           );
              //           reduced.newExcludedFileUUIDs.push(...fileUUIDs);
              //         }

              //         return reduced;
              //       },
              //       {
              //         newExcludedStorageGroupUUIDs: [],
              //         newExcludedFileUUIDs: [],
              //       },
              //     ));

              //   includedFileUUIDs.forEach((fileUUID) => {
              //     newExcludedFileUUIDs.splice(
              //       newExcludedFileUUIDs.indexOf(fileUUID),
              //       1,
              //     );
              //   });
              // }

              // setIncludeStorageGroupUUIDs(newExcludedStorageGroupUUIDs);
              // setIncludeFileUUIDs(newExcludedFileUUIDs);

              // const newStorageGroupValue = storageGroupValue.filter(
              //   (uuid) => !newExcludedStorageGroupUUIDs.includes(uuid),
              // );
              // setStorageGroupValue(newStorageGroupValue);

              // newExcludedFileUUIDs.forEach((excludedFileUUID) => {
              //   if (installISOFileUUID === excludedFileUUID) {
              //     setInstallISOFileUUID('');
              //   }

              //   if (driverISOFileUUID === excludedFileUUID) {
              //     setDriverISOFileUUID('');
              //   }
              // });

              // const {
              //   maxCPUCores: localMaxCPUCores,
              //   maxMemory: localMaxMemory,
              //   maxVirtualDiskSize: localMaxVDSize,
              // } = getMaxAvailableValues(organizedAnvils, {
              //   includeAnvilUUIDs: subsetAnvilUUIDs,
              //   includeStorageGroupUUIDs: newStorageGroupValue,
              // });

              // setInputCPUCoresMax(localMaxCPUCores);
              // setInputMemoryMax(localMaxMemory);
              // setInputVirtualDiskSizeMax(localMaxVDSize);
            },
            value: anvilValue,
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
