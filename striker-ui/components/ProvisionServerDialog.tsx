import { useEffect, useState } from 'react';
import { Dialog, DialogProps, FormControl, FormGroup } from '@mui/material';
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
  anvilMaxAvailableStorage: bigint;
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
  storageGroups: Array<
    Omit<
      StorageGroupMetadataForProvisionServer,
      'storageGroupSize' | 'storageGroupFree'
    > & {
      storageGroupSize: bigint;
      storageGroupFree: bigint;
    }
  >;
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
          storageGroupUUID: '271651b0-c064-401b-9391-549bbced2383',
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

const DATA_SIZE_UNITS: DataSizeUnit[] = [
  'B',
  'KiB',
  'MiB',
  'GiB',
  'TiB',
  'kB',
  'MB',
  'GB',
  'TB',
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
  selectItems: [string, string][] | string[],
  selectProps?: Partial<SelectProps>,
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
      {selectItems.map((item) => {
        let itemValue;
        let itemDisplayValue;

        if (item instanceof Array) {
          [itemValue, itemDisplayValue] = item;
        } else {
          itemValue = item;
          itemDisplayValue = item;
        }

        return (
          <MenuItem key={`${id}-${itemValue}`} value={itemValue}>
            {itemDisplayValue}
          </MenuItem>
        );
      })}
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
  selectItems: [string, string][] | string[],
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
    {createOutlinedSelect(
      `${id}-nested-select`,
      undefined,
      selectItems,
      selectProps,
    )}
  </FormControl>
);

const organizeAnvils = (
  data: AnvilDetailMetadataForProvisionServer[],
): OrganizedAnvilDetailMetadataForProvisionServer[] =>
  data.map((anvil) => {
    const anvilMaxAvailableStorage = anvil.storageGroups.reduce<bigint>(
      (reducedStorageGroupFree, { storageGroupFree }) => {
        const convertedStorageGroupFree = BigInt(storageGroupFree);

        return convertedStorageGroupFree > reducedStorageGroupFree
          ? convertedStorageGroupFree
          : reducedStorageGroupFree;
      },
      BIGINT_ZERO,
    );

    return {
      ...anvil,
      anvilTotalMemory: BigInt(anvil.anvilTotalMemory),
      anvilTotalAllocatedMemory: BigInt(anvil.anvilTotalAllocatedMemory),
      anvilTotalAvailableMemory: BigInt(anvil.anvilTotalAvailableMemory),
      anvilMaxAvailableStorage,
      hosts: anvil.hosts.map((host) => ({
        ...host,
        hostMemory: BigInt(host.hostMemory),
      })),
      servers: anvil.servers.map((server) => ({
        ...server,
        serverMemory: BigInt(server.serverMemory),
      })),
      storageGroups: anvil.storageGroups.map((storageGroup) => ({
        ...storageGroup,
        storageGroupSize: BigInt(storageGroup.storageGroupSize),
        storageGroupFree: BigInt(storageGroup.storageGroupFree),
      })),
    };
  });

const getMaxAvailableValues = (
  anvils: OrganizedAnvilDetailMetadataForProvisionServer[],
) =>
  anvils.reduce<{
    maxAvailableCPUCores: number;
    maxAvailableMemory: bigint;
    maxAvailableVirtualDiskSize: bigint;
  }>(
    (
      reducedValues,
      {
        anvilTotalAvailableCPUCores,
        anvilTotalAvailableMemory,
        anvilMaxAvailableStorage,
      },
    ) => {
      reducedValues.maxAvailableCPUCores = Math.max(
        anvilTotalAvailableCPUCores,
        reducedValues.maxAvailableCPUCores,
      );

      if (anvilTotalAvailableMemory > reducedValues.maxAvailableMemory) {
        reducedValues.maxAvailableMemory = anvilTotalAvailableMemory;
      }

      if (
        anvilMaxAvailableStorage > reducedValues.maxAvailableVirtualDiskSize
      ) {
        reducedValues.maxAvailableVirtualDiskSize = anvilMaxAvailableStorage;
      }

      return reducedValues;
    },
    {
      maxAvailableCPUCores: 0,
      maxAvailableMemory: BIGINT_ZERO,
      maxAvailableVirtualDiskSize: BIGINT_ZERO,
    },
  );

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
  virtualDiskSize: bigint,
) =>
  organizedAnvils
    .filter((anvil) => {
      const isEnoughCPUCores = cpuCores <= anvil.anvilTotalAvailableCPUCores;
      const isEnoughMemory = memory <= anvil.anvilTotalAvailableMemory;
      const isEnoughStorage = virtualDiskSize <= anvil.anvilMaxAvailableStorage;

      return isEnoughCPUCores && isEnoughMemory && isEnoughStorage;
    })
    .map(({ anvilUUID, anvilName }) => [anvilUUID, anvilName]);

/**
 * 1. Fetch anvils detail for provision server from the back-end.
 * 2. Get the max values for CPU cores, memory, and virtual disk size.
 */

const ProvisionServerDialog = ({
  dialogProps: { open },
}: ProvisionServerDialogProps): JSX.Element => {
  const [sliderCPUCoresMax, setSliderCPUCoresMax] = useState<number>(0);
  // const [sliderMemoryMax, setSliderMemoryMax] = useState<number>(0);

  const [cpuCoresValue, setCPUCoresValue] = useState<number>(1);

  const [memoryValue, setMemoryValue] = useState<bigint>(BIGINT_ZERO);
  const [inputMemoryValue, setInputMemoryValue] = useState<string>('');
  const [inputMemoryUnit, setInputMemoryUnit] = useState<DataSizeUnit>('B');

  const [virtualDiskSizeValue, setVirtualDiskSizeValue] =
    useState<bigint>(BIGINT_ZERO);
  const [inputVirtualDiskSizeValue, setInputVirtualDiskSizeValue] =
    useState<string>('');
  const [inputVirtualDiskSizeUnit, setInputVirtualDiskSizeUnit] =
    useState<DataSizeUnit>('B');

  // const [storageGroupUUID, setStorageGroupUUID] = useState<string>('');

  const data = MOCK_DATA;

  const organizedAnvils = organizeAnvils(data.anvils);

  const {
    maxAvailableCPUCores,
    maxAvailableMemory,
    maxAvailableVirtualDiskSize,
  } = getMaxAvailableValues(organizedAnvils);

  // const optimizeOSList = data.osList.map((keyValuePair) =>
  //   keyValuePair.split(','),
  // );

  useEffect(() => {
    setSliderCPUCoresMax(maxAvailableCPUCores);

    dSize(maxAvailableMemory, {
      onSuccess: {
        number: (value, unit) => {
          setSliderMemoryMax(value);
          setInputMemoryUnit(unit);
        },
      },
    });
  }, [maxAvailableCPUCores, maxAvailableMemory, maxAvailableVirtualDiskSize]);

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
            onChange: (event, value) => {
              setCPUCoresValue(value as number);
            },
            max: sliderCPUCoresMax,
            min: 1,
          },
        })}
        <BodyText text={`Memory: ${memoryValue.toString()}`} />
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
          text={`Virtual disk size: ${virtualDiskSizeValue.toString()}`}
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
        {/*
        {createOutlinedSelect('ps-storage-group', 'Storage group', [
          ['b594f417-852a-4bd4-a215-fae32d226b0b', 'Storage group 1'],
        ])}
        {createOutlinedSlider('ps-image-size', 'Virtual disk size')}
        {createOutlinedSelect('ps-install-image', 'Install ISO', [])}
        {createOutlinedSelect('ps-driver-image', 'Driver ISO', [])}
        {createOutlinedSelect(
          'ps-optimize-for-os',
          'Optimize for OS',
          optimizeOSList,
        )} */}
        {filterAnvils(
          organizedAnvils,
          cpuCoresValue,
          memoryValue,
          virtualDiskSizeValue,
        ).map(([anvilUUID, anvilName]) => (
          <BodyText
            key={`ps-filtered-anvils-${anvilUUID}`}
            text={`${anvilUUID},${anvilName}`}
          />
        ))}
      </FormGroup>
      <ContainedButton>Provision</ContainedButton>
    </Dialog>
  );
};

export default ProvisionServerDialog;
