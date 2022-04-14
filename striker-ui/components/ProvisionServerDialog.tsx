import { useEffect, useState } from 'react';
import {
  Box,
  Dialog,
  DialogProps,
  FormControl,
  FormGroup,
} from '@mui/material';
import { dSize, dSizeStr } from 'format-data-size';

import MenuItem from './MenuItem';
import OutlinedInput from './OutlinedInput';
import OutlinedInputLabel from './OutlinedInputLabel';
import { Panel, PanelHeader } from './Panels';
import Select from './Select';
import Slider, { SliderProps } from './Slider';
import { BodyText, HeaderText } from './Text';

type ProvisionServerDialogProps = {
  dialogProps: DialogProps;
};

const BIGINT_ZERO = BigInt(0);

const createOutlinedInput = (id: string, label: string): JSX.Element => (
  <FormControl>
    <OutlinedInputLabel {...{ htmlFor: id }}>{label}</OutlinedInputLabel>
    <OutlinedInput {...{ id, label }} />
  </FormControl>
);

const createOutlinedSelect = (
  id: string,
  label: string | undefined,
  value: string,
  selectItems: string[][] | string[],
): JSX.Element => (
  <FormControl>
    {label && (
      <OutlinedInputLabel {...{ htmlFor: id }}>{label}</OutlinedInputLabel>
    )}
    <Select {...{ id, input: <OutlinedInput {...{ label }} />, value }}>
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
  sliderProps?: Partial<SliderProps>,
): JSX.Element => (
  <FormControl>
    <Slider
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        isAllowTextInput: true,
        label,
        labelId: `${id}-label`,
        value: 1,
        ...sliderProps,
      }}
    />
  </FormControl>
);

const ProvisionServerDialog = ({
  dialogProps: { open },
}: ProvisionServerDialogProps): JSX.Element => {
  const [sliderMaxAvailableCPUCores, setSliderMaxAvailableCPUCores] =
    useState<number>(0);
  const [sliderMaxAvailableMemory, setSliderMaxAvailableMemory] =
    useState<number>(0);

  const [memory, setMemory] = useState<bigint>(BIGINT_ZERO);
  const [memoryUnit, setMemoryUnit] = useState<string>('');

  const data = {
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
        storageGroups: [],
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

  const { maxAvailableCPUCores, maxAvailableMemory } = data.anvils.reduce<{
    maxAvailableCPUCores: number;
    maxAvailableMemory: bigint;
  }>(
    (
      reducedValues,
      { anvilTotalAvailableCPUCores, anvilTotalAvailableMemory },
    ) => {
      const convertedAnvilTotalAvailableMemory = BigInt(
        anvilTotalAvailableMemory,
      );

      reducedValues.maxAvailableCPUCores = Math.max(
        anvilTotalAvailableCPUCores,
        reducedValues.maxAvailableCPUCores,
      );

      if (
        convertedAnvilTotalAvailableMemory > reducedValues.maxAvailableMemory
      ) {
        reducedValues.maxAvailableMemory = convertedAnvilTotalAvailableMemory;
      }

      return reducedValues;
    },
    {
      maxAvailableCPUCores: 0,
      maxAvailableMemory: BIGINT_ZERO,
    },
  );

  const optimizeOSList = data.osList.map((keyValuePair) =>
    keyValuePair.split(','),
  );

  useEffect(() => {
    setSliderMaxAvailableCPUCores(maxAvailableCPUCores);

    const formattedMaxAvailableMemory = dSize(maxAvailableMemory, {
      precision: 2,
    });

    console.dir(formattedMaxAvailableMemory, { depth: null });

    if (formattedMaxAvailableMemory) {
      setSliderMaxAvailableMemory(
        parseFloat(formattedMaxAvailableMemory.value),
      );

      setMemoryUnit(formattedMaxAvailableMemory.unit);
    }
  }, [maxAvailableCPUCores, maxAvailableMemory]);

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
        {createOutlinedSlider('ps-cpu-cores', 'CPU cores', {
          sliderProps: { max: sliderMaxAvailableCPUCores, min: 1 },
        })}
        <BodyText text={`Memory: ${memory.toString()}`} />
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'row',

            '& > :first-child': {
              flexGrow: 1,
            },
          }}
        >
          {createOutlinedSlider('ps-memory', 'Memory', {
            sliderProps: {
              max: sliderMaxAvailableMemory,
              min: 1,
              onChange: (event, newValue) => {
                console.log(`newValue=${newValue}`);
              },
            },
          })}
          {createOutlinedSelect('ps-memory-unit', undefined, memoryUnit, [
            'B',
            'KiB',
            'kB',
            'MiB',
            'MB',
            'GiB',
            'GB',
            'TiB',
            'TB',
          ])}
        </Box>
        {/* {createOutlinedSlider('ps-memory', 'Memory')}
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
      </FormGroup>
    </Dialog>
  );
};

export default ProvisionServerDialog;
