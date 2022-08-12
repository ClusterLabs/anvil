import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  iconButtonClasses as muiIconButtonClasses,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import {
  Add as MUIAddIcon,
  Check as MUICheckIcon,
  DragHandle as MUIDragHandleIcon,
} from '@mui/icons-material';
import {
  DataGrid as MUIDataGrid,
  DataGridProps as MUIDataGridProps,
  gridClasses as muiGridClasses,
} from '@mui/x-data-grid';
import {
  Dispatch,
  FC,
  forwardRef,
  MutableRefObject,
  SetStateAction,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';
import { v4 as uuidv4 } from 'uuid';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import { BLUE, GREY } from '../lib/consts/DEFAULT_THEME';
import { REP_IPV4, REP_IPV4_CSV } from '../lib/consts/REG_EXP_PATTERNS';

import BriefNetworkInterface from './BriefNetworkInterface';
import Decorator from './Decorator';
import DropArea from './DropArea';
import FlexBox from './FlexBox';
import IconButton from './IconButton';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import { Message } from './MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from './MessageGroup';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { InnerPanel, InnerPanelHeader } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import SelectWithLabel from './SelectWithLabel';
import Spinner from './Spinner';
import sumstring from '../lib/sumstring';
import { testInput, testNotBlank } from '../lib/test_input';
import { InputTestBatches } from '../types/TestInputFunction';
import { BodyText, DataGridCellText } from './Text';

type NetworkInput = {
  inputUUID: string;
  interfaces: (NetworkInterfaceOverviewMetadata | undefined)[];
  ipAddress: string;
  ipAddressInputRef?: MutableRefObject<InputForwardedRefContent<'string'>>;
  name?: string;
  subnetMask: string;
  subnetMaskInputRef?: MutableRefObject<InputForwardedRefContent<'string'>>;
  type: string;
};

type NetworkInterfaceInputMap = Record<
  string,
  {
    isApplied?: boolean;
  }
>;

type NetworkInitFormForwardRefContent = {
  get?: () => {
    domainNameServerCSV?: string;
    gateway?: string;
    networks: Omit<
      NetworkInput,
      'inputUUID' | 'ipAddressInputRef' | 'subnetMaskInputRef'
    >[];
  };
};

const MOCK_NICS: NetworkInterfaceOverviewMetadata[] = [
  {
    networkInterfaceUUID: 'fe299134-c8fe-47bd-ab7a-3aa95eada1f6',
    networkInterfaceMACAddress: '52:54:00:d2:31:36',
    networkInterfaceName: 'ens10',
    networkInterfaceState: 'up',
    networkInterfaceSpeed: 10000,
    networkInterfaceOrder: 1,
  },
  {
    networkInterfaceUUID: 'a652bfd5-61ac-4495-9881-185be8a2ac74',
    networkInterfaceMACAddress: '52:54:00:d4:4d:b5',
    networkInterfaceName: 'ens11',
    networkInterfaceState: 'up',
    networkInterfaceSpeed: 10000,
    networkInterfaceOrder: 2,
  },
  {
    networkInterfaceUUID: 'b8089b40-0969-49c3-ad65-2470ddb420ef',
    networkInterfaceMACAddress: '52:54:00:ba:f5:a3',
    networkInterfaceName: 'ens3',
    networkInterfaceState: 'up',
    networkInterfaceSpeed: 10000,
    networkInterfaceOrder: 3,
  },
  {
    networkInterfaceUUID: '42a17465-31b1-4e47-9a91-f803f22ffcc1',
    networkInterfaceMACAddress: '52:54:00:ae:31:70',
    networkInterfaceName: 'ens9',
    networkInterfaceState: 'up',
    networkInterfaceSpeed: 10000,
    networkInterfaceOrder: 4,
  },
];

const NETWORK_TYPES: Record<string, string> = {
  bcn: 'Back-Channel Network',
  ifn: 'Internet-Facing Network',
};

const REQUIRED_NETWORKS: NetworkInput[] = [
  {
    inputUUID: '30dd2ac5-8024-4a7e-83a1-6a3df7218972',
    interfaces: [],
    ipAddress: '10.200.1.1',
    name: `${NETWORK_TYPES.bcn} 1`,
    subnetMask: '255.255.0.0',
    type: 'bcn',
  },
  {
    inputUUID: 'e7ef3af5-5602-440c-87f8-69c242e3d7f3',
    interfaces: [],
    ipAddress: '10.201.1.1',
    name: `${NETWORK_TYPES.ifn} 1`,
    subnetMask: '255.255.0.0',
    type: 'ifn',
  },
];

const BASE_INPUT_COUNT = 2;
const MAX_INTERFACES_PER_NETWORK = 2;
const PER_NETWORK_INPUT_COUNT = 3;
const INPUT_TEST_IDS = {
  dnsCSV: 'domainNameServerCSV',
  gateway: 'gateway',
  networkName: (prefix: string) => `${prefix}Name`,
  networkIPAddress: (prefix: string) => `${prefix}IPAddress`,
  networkSubnet: (prefix: string) => `${prefix}SubnetMask`,
};

const NETWORK_INTERFACE_TEMPLATE = Array.from(
  { length: MAX_INTERFACES_PER_NETWORK },
  (unused, index) => index + 1,
);

const createNetworkInterfaceTableColumns = (
  handleDragMouseDown: (
    row: NetworkInterfaceOverviewMetadata,
    ...eventArgs: Parameters<Exclude<MUIBoxProps['onMouseDown'], undefined>>
  ) => void,
  networkInterfaceInputMap: NetworkInterfaceInputMap,
): MUIDataGridProps['columns'] => [
  {
    align: 'center',
    field: '',
    renderCell: ({ row }) => {
      const { isApplied } =
        networkInterfaceInputMap[row.networkInterfaceUUID] ?? false;

      let cursor = 'grab';
      let handleMouseDown: MUIBoxProps['onMouseDown'] = (...eventArgs) => {
        handleDragMouseDown(row, ...eventArgs);
      };
      let icon = <MUIDragHandleIcon />;

      if (isApplied) {
        cursor = 'auto';
        handleMouseDown = undefined;
        icon = <MUICheckIcon sx={{ color: BLUE }} />;
      }

      return (
        <MUIBox
          onMouseDown={handleMouseDown}
          sx={{
            alignItems: 'center',
            display: 'flex',
            flexDirection: 'row',

            '&:hover': { cursor },
          }}
        >
          {icon}
        </MUIBox>
      );
    },
    sortable: false,
    width: 1,
  },
  {
    field: 'networkInterfaceName',
    flex: 1,
    headerName: 'Name',
    renderCell: ({ row: { networkInterfaceState } = {}, value }) => (
      <MUIBox
        sx={{
          display: 'flex',
          flexDirection: 'row',
          '& > :not(:first-child)': { marginLeft: '.5em' },
        }}
      >
        <Decorator
          colour={networkInterfaceState === 'up' ? 'ok' : 'off'}
          sx={{ height: 'auto' }}
        />
        <DataGridCellText text={value} />
      </MUIBox>
    ),
    sortComparator: (v1, v2) => sumstring(v1) - sumstring(v2),
  },
  {
    field: 'networkInterfaceMACAddress',
    flex: 1,
    headerName: 'MAC',
    renderCell: ({ value }) => <DataGridCellText monospaced text={value} />,
  },
  {
    field: 'networkInterfaceState',
    flex: 1,
    headerName: 'State',
    renderCell: ({ value }) => {
      const state = String(value);

      return (
        <DataGridCellText
          text={`${state.charAt(0).toUpperCase()}${state.substring(1)}`}
        />
      );
    },
  },
  {
    field: 'networkInterfaceSpeed',
    flex: 1,
    headerName: 'Speed',
    renderCell: ({ value }) => (
      <DataGridCellText text={`${parseFloat(value).toLocaleString()} Mbps`} />
    ),
  },
  {
    field: 'networkInterfaceOrder',
    flex: 1,
    headerName: 'Order',
  },
];

const NetworkForm: FC<{
  createDropMouseUpHandler?: (
    interfaces: (NetworkInterfaceOverviewMetadata | undefined)[],
    interfaceIndex: number,
  ) => MUIBoxProps['onMouseUp'];
  getNetworkTypeCount: (targetType: string, lastIndex?: number) => number;
  inputTests: InputTestBatches;
  networkIndex: number;
  networkInput: NetworkInput;
  networkInputs: NetworkInput[];
  networkInterfaceInputMap: NetworkInterfaceInputMap;
  optionalNetworkInputsLength: number;
  setNetworkInputs: Dispatch<SetStateAction<NetworkInput[]>>;
  setNetworkInterfaceInputMap: Dispatch<
    SetStateAction<NetworkInterfaceInputMap>
  >;
  testAllInputs: (...excludeTestIds: string[]) => boolean;
  toggleSubmitDisabled?: ToggleSubmitDisabledFunction;
}> = ({
  createDropMouseUpHandler,
  getNetworkTypeCount,
  inputTests,
  networkIndex,
  networkInput,
  networkInputs,
  networkInterfaceInputMap,
  optionalNetworkInputsLength,
  setNetworkInputs,
  setNetworkInterfaceInputMap,
  testAllInputs,
  toggleSubmitDisabled,
}) => {
  const theme = useTheme();
  const breakpointMedium = useMediaQuery(theme.breakpoints.up('md'));
  const breakpointLarge = useMediaQuery(theme.breakpoints.up('lg'));

  const ipAddressInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const subnetMaskInputRef = useRef<InputForwardedRefContent<'string'>>({});

  const { inputUUID, interfaces, ipAddress, subnetMask, type } = networkInput;

  const inputTestPrefix = useMemo(
    () => `network${networkIndex}`,
    [networkIndex],
  );
  const ipAddressInputTestId = useMemo(
    () => INPUT_TEST_IDS.networkIPAddress(inputTestPrefix),
    [inputTestPrefix],
  );
  const subnetMaskInputTestId = useMemo(
    () => INPUT_TEST_IDS.networkSubnet(inputTestPrefix),
    [inputTestPrefix],
  );

  const isNetworkOptional = useMemo(
    () => networkIndex < optionalNetworkInputsLength,
    [networkIndex, optionalNetworkInputsLength],
  );

  networkInput.ipAddressInputRef = ipAddressInputRef;
  networkInput.subnetMaskInputRef = subnetMaskInputRef;

  return (
    <InnerPanel>
      <InnerPanelHeader>
        <SelectWithLabel
          id={`network-${inputUUID}-name`}
          isReadOnly={!isNetworkOptional}
          inputLabelProps={{ isNotifyRequired: true }}
          label="Network name"
          selectItems={Object.entries(NETWORK_TYPES).map(
            ([networkType, networkTypeName]) => {
              let count = getNetworkTypeCount(networkType, networkIndex);

              if (networkType !== type) {
                count += 1;
              }

              const displayValue = `${networkTypeName} ${count}`;

              return { value: networkType, displayValue };
            },
          )}
          selectProps={{
            onChange: ({ target: { value } }) => {
              const networkType = String(value);

              networkInput.type = networkType;
              networkInput.name = `${
                NETWORK_TYPES[networkType]
              } ${getNetworkTypeCount(networkType, networkIndex)}`;

              setNetworkInputs([...networkInputs]);
            },
            renderValue: breakpointLarge
              ? undefined
              : (value) =>
                  `${String(value).toUpperCase()} ${getNetworkTypeCount(
                    type,
                    networkIndex,
                  )}`,
            value: type,
          }}
        />
      </InnerPanelHeader>
      <MUIBox
        sx={{
          display: 'flex',
          flexDirection: 'column',
          margin: '.6em',

          '& > :not(:first-child)': {
            marginTop: '1em',
          },
        }}
      >
        {NETWORK_INTERFACE_TEMPLATE.map((linkNumber) => {
          const linkName = `Link ${linkNumber}`;
          const networkInterfaceIndex = linkNumber - 1;
          const networkInterface = interfaces[networkInterfaceIndex];
          const { networkInterfaceUUID = '' } = networkInterface ?? {};

          const emptyDropAreaContent = breakpointMedium ? (
            <BodyText text="Drop to add interface." />
          ) : (
            <MUIAddIcon
              sx={{
                alignSelf: 'center',
                color: GREY,
              }}
            />
          );

          return (
            <MUIBox
              key={`network-${inputUUID}-link-${linkNumber}`}
              sx={{
                alignItems: 'center',
                display: 'flex',
                flexDirection: 'row',

                '& > :not(:first-child)': {
                  marginLeft: '1em',
                },

                '& > :last-child': {
                  flexGrow: 1,
                },
              }}
            >
              <BodyText sx={{ whiteSpace: 'nowrap' }} text={linkName} />
              <DropArea
                onMouseUp={createDropMouseUpHandler?.call(
                  null,
                  interfaces,
                  networkInterfaceIndex,
                )}
              >
                {networkInterface ? (
                  <BriefNetworkInterface
                    key={`network-interface-${networkInterfaceUUID}`}
                    networkInterface={networkInterface}
                    onClose={() => {
                      interfaces[networkInterfaceIndex] = undefined;
                      networkInterfaceInputMap[networkInterfaceUUID].isApplied =
                        false;

                      setNetworkInterfaceInputMap({
                        ...networkInterfaceInputMap,
                      });
                    }}
                  />
                ) : (
                  emptyDropAreaContent
                )}
              </DropArea>
            </MUIBox>
          );
        })}
        <InputWithRef
          input={
            <OutlinedInputWithLabel
              id={`network-${inputUUID}-ip-address`}
              inputLabelProps={{ isNotifyRequired: true }}
              label="IP address"
              onChange={({ target: { value } }) => {
                const isLocalValid = testInput({
                  inputs: {
                    [ipAddressInputTestId]: {
                      value,
                    },
                  },
                  tests: inputTests,
                });

                toggleSubmitDisabled?.call(
                  null,
                  isLocalValid && testAllInputs(ipAddressInputTestId),
                );
              }}
              value={ipAddress}
            />
          }
          ref={ipAddressInputRef}
        />
        <InputWithRef
          input={
            <OutlinedInputWithLabel
              id={`network-${inputUUID}-subnet-mask`}
              inputLabelProps={{ isNotifyRequired: true }}
              label="Subnet mask"
              onChange={({ target: { value } }) => {
                const isLocalValid = testInput({
                  inputs: {
                    [subnetMaskInputTestId]: { value },
                  },
                  tests: inputTests,
                });

                toggleSubmitDisabled?.call(
                  null,
                  isLocalValid && testAllInputs(subnetMaskInputTestId),
                );
              }}
              value={subnetMask}
            />
          }
          ref={subnetMaskInputRef}
        />
      </MUIBox>
    </InnerPanel>
  );
};

NetworkForm.defaultProps = {
  createDropMouseUpHandler: undefined,
  toggleSubmitDisabled: undefined,
};

const NetworkInitForm = forwardRef<
  NetworkInitFormForwardRefContent,
  { toggleSubmitDisabled?: (testResult: boolean) => void }
>(({ toggleSubmitDisabled }, ref) => {
  const [dragMousePosition, setDragMousePosition] = useState<{
    x: number;
    y: number;
  }>({ x: 0, y: 0 });
  const [networkInterfaceInputMap, setNetworkInterfaceInputMap] =
    useState<NetworkInterfaceInputMap>({});
  const [networkInputs, setNetworkInputs] =
    useState<NetworkInput[]>(REQUIRED_NETWORKS);
  const [networkInterfaceHeld, setNetworkInterfaceHeld] = useState<
    NetworkInterfaceOverviewMetadata | undefined
  >();

  const gatewayInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const dnsCSVInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const { data: networkInterfaces = MOCK_NICS, isLoading } = periodicFetch<
    NetworkInterfaceOverviewMetadata[]
  >(`${API_BASE_URL}/network-interface`, {
    refreshInterval: 2000,
    onSuccess: (data) => {
      if (data instanceof Array) {
        const map = data.reduce<NetworkInterfaceInputMap>(
          (reduceContainer, { networkInterfaceUUID }) => {
            reduceContainer[networkInterfaceUUID] =
              networkInterfaceInputMap[networkInterfaceUUID] ?? {};

            return reduceContainer;
          },
          {},
        );

        setNetworkInterfaceInputMap(map);
      }
    },
  });

  const optionalNetworkInputsLength: number = useMemo(
    () => networkInputs.length - 2,
    [networkInputs],
  );
  const isDisableAddNetworkButton: boolean = useMemo(
    () =>
      networkInputs.length >= networkInterfaces.length ||
      Object.values(networkInterfaceInputMap).every(
        ({ isApplied }) => isApplied,
      ),
    [networkInputs, networkInterfaces, networkInterfaceInputMap],
  );

  const setGatewayInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 0, message),
    [],
  );
  const setDomainNameServerCSVInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 1, message),
    [],
  );
  const getNetworkInputMessageIndex = useCallback(
    (networkIndex: number, inputIndex: number) =>
      BASE_INPUT_COUNT +
      (networkInputs.length - 1 - networkIndex) * PER_NETWORK_INPUT_COUNT +
      inputIndex,
    [networkInputs],
  );
  const setNetworkIPAddressInputMessage = useCallback(
    (networkIndex: number, message?: Message) =>
      messageGroupRef.current.setMessage?.call(
        null,
        getNetworkInputMessageIndex(networkIndex, 1),
        message,
      ),
    [getNetworkInputMessageIndex],
  );
  const setNetworkSubnetMaskInputMessage = useCallback(
    (networkIndex: number, message?: Message) =>
      messageGroupRef.current.setMessage?.call(
        null,
        getNetworkInputMessageIndex(networkIndex, 2),
        message,
      ),
    [getNetworkInputMessageIndex],
  );

  const inputTests: InputTestBatches = useMemo(() => {
    const tests: InputTestBatches = {
      [INPUT_TEST_IDS.dnsCSV]: {
        defaults: {
          getValue: () => dnsCSVInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setDomainNameServerCSVInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setDomainNameServerCSVInputMessage({
                children:
                  'Domain name servers should be a comma-separated list of IPv4 addresses without trailing comma(s).',
              });
            },
            test: ({ value }) => REP_IPV4_CSV.test(value as string),
          },
          { test: testNotBlank },
        ],
      },
      [INPUT_TEST_IDS.gateway]: {
        defaults: {
          getValue: () => gatewayInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setGatewayInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setGatewayInputMessage({
                children: 'Gateway should be a valid IPv4 address.',
              });
            },
            test: ({ value }) => REP_IPV4.test(value as string),
          },
          { test: testNotBlank },
        ],
      },
    };

    networkInputs.forEach(({ ipAddress, name, subnetMask }, networkIndex) => {
      const inputTestPrefix = `network${networkIndex}`;

      tests[INPUT_TEST_IDS.networkName(inputTestPrefix)] = {
        defaults: { value: name },
        tests: [{ test: testNotBlank }],
      };
      tests[INPUT_TEST_IDS.networkIPAddress(inputTestPrefix)] = {
        defaults: {
          onSuccess: () => {
            setNetworkIPAddressInputMessage(networkIndex, undefined);
          },
          value: ipAddress,
        },
        tests: [
          {
            onFailure: () => {
              setNetworkIPAddressInputMessage(networkIndex, {
                children: `IP address in ${name} must be a valid IPv4 address.`,
              });
            },
            test: ({ value }) => REP_IPV4.test(value as string),
          },
          { test: testNotBlank },
        ],
      };
      tests[INPUT_TEST_IDS.networkSubnet(inputTestPrefix)] = {
        defaults: {
          onSuccess: () => {
            setNetworkSubnetMaskInputMessage(networkIndex, undefined);
          },
          value: subnetMask,
        },
        tests: [
          {
            onFailure: () => {
              setNetworkSubnetMaskInputMessage(networkIndex, {
                children: `Subnet mask in ${name} must be a valid IPv4 address.`,
              });
            },
            test: ({ value }) => REP_IPV4.test(value as string),
          },
          { test: testNotBlank },
        ],
      };
    });

    return tests;
  }, [
    networkInputs,
    setDomainNameServerCSVInputMessage,
    setGatewayInputMessage,
    setNetworkIPAddressInputMessage,
    setNetworkSubnetMaskInputMessage,
  ]);

  const testAllInputs = useCallback(
    (...excludeTestIds: string[]) =>
      testInput({
        excludeTestIds,
        isIgnoreOnCallbacks: true,
        tests: inputTests,
      }),
    [inputTests],
  );
  const clearNetworkInterfaceHeld = useCallback(() => {
    setNetworkInterfaceHeld(undefined);
  }, []);
  const createNetwork = useCallback(() => {
    networkInputs.unshift({
      inputUUID: uuidv4(),
      interfaces: [],
      ipAddress: '',
      name: 'Unknown Network',
      subnetMask: '',
      type: '',
    });

    setNetworkInputs([...networkInputs]);
  }, [networkInputs]);
  const getNetworkTypeCount = useCallback(
    (targetType: string, lastIndex = 0) => {
      let count = 0;

      for (
        let index = networkInputs.length - 1;
        index >= lastIndex;
        index -= 1
      ) {
        if (networkInputs[index].type === targetType) {
          count += 1;
        }
      }

      return count;
    },
    [networkInputs],
  );

  const createDropMouseUpHandler:
    | ((
        interfaces: (NetworkInterfaceOverviewMetadata | undefined)[],
        interfaceIndex: number,
      ) => MUIBoxProps['onMouseUp'])
    | undefined = useMemo(() => {
    if (networkInterfaceHeld === undefined) {
      return undefined;
    }

    const { networkInterfaceUUID } = networkInterfaceHeld;

    return (
        interfaces: (NetworkInterfaceOverviewMetadata | undefined)[],
        interfaceIndex: number,
      ) =>
      () => {
        const { networkInterfaceUUID: previousNetworkInterfaceUUID } =
          interfaces[interfaceIndex] ?? {};

        if (
          previousNetworkInterfaceUUID &&
          previousNetworkInterfaceUUID !== networkInterfaceUUID
        ) {
          networkInterfaceInputMap[previousNetworkInterfaceUUID].isApplied =
            false;
        }

        interfaces[interfaceIndex] = networkInterfaceHeld;
        networkInterfaceInputMap[networkInterfaceUUID].isApplied = true;
      };
  }, [networkInterfaceHeld, networkInterfaceInputMap]);
  const dragAreaDraggingSx: MUIBoxProps['sx'] = useMemo(
    () => (networkInterfaceHeld ? { cursor: 'grabbing' } : {}),
    [networkInterfaceHeld],
  );
  const floatingNetworkInterface: JSX.Element = useMemo(() => {
    if (networkInterfaceHeld === undefined) {
      return <></>;
    }

    const { x, y } = dragMousePosition;

    return (
      <BriefNetworkInterface
        isFloating
        networkInterface={networkInterfaceHeld}
        sx={{
          left: `calc(${x}px + .4em)`,
          position: 'absolute',
          top: `calc(${y}px - 1.6em)`,
          zIndex: 20,
        }}
      />
    );
  }, [dragMousePosition, networkInterfaceHeld]);
  const handleDragAreaMouseLeave: MUIBoxProps['onMouseLeave'] = useMemo(
    () =>
      networkInterfaceHeld
        ? () => {
            clearNetworkInterfaceHeld();
          }
        : undefined,
    [clearNetworkInterfaceHeld, networkInterfaceHeld],
  );
  const handleDragAreaMouseMove: MUIBoxProps['onMouseMove'] = useMemo(
    () =>
      networkInterfaceHeld
        ? ({ currentTarget, nativeEvent: { clientX, clientY } }) => {
            const { left, top } = currentTarget.getBoundingClientRect();

            setDragMousePosition({
              x: clientX - left,
              y: clientY - top,
            });
          }
        : undefined,
    [networkInterfaceHeld],
  );
  const handleDragAreaMouseUp: MUIBoxProps['onMouseUp'] = useMemo(
    () =>
      networkInterfaceHeld
        ? () => {
            clearNetworkInterfaceHeld();
          }
        : undefined,
    [clearNetworkInterfaceHeld, networkInterfaceHeld],
  );

  useEffect(() => {
    const map = networkInterfaces.reduce<NetworkInterfaceInputMap>(
      (reduceContainer, { networkInterfaceUUID }) => {
        reduceContainer[networkInterfaceUUID] =
          networkInterfaceInputMap[networkInterfaceUUID] ?? {};

        return reduceContainer;
      },
      {},
    );

    setNetworkInterfaceInputMap(map);

    // This block inits the input map for the MOCK_NICS.
    // TODO: remove after testing.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useImperativeHandle(
    ref,
    () => ({
      get: () => ({
        domainNameServerCSV: dnsCSVInputRef.current.getValue?.call(null),
        gateway: gatewayInputRef.current.getValue?.call(null),
        networks: networkInputs.map(
          (
            { interfaces, ipAddressInputRef, subnetMaskInputRef, type },
            networkIndex,
          ) => ({
            interfaces,
            ipAddress: ipAddressInputRef?.current.getValue?.call(null) ?? '',
            name: `${NETWORK_TYPES[type]} ${getNetworkTypeCount(
              type,
              networkIndex,
            )}`,
            subnetMask: subnetMaskInputRef?.current.getValue?.call(null) ?? '',
            type,
          }),
        ),
      }),
    }),
    [getNetworkTypeCount, networkInputs],
  );

  return isLoading ? (
    <Spinner />
  ) : (
    <MUIBox
      onMouseDown={({ clientX, clientY, currentTarget }) => {
        const { left, top } = currentTarget.getBoundingClientRect();

        setDragMousePosition({
          x: clientX - left,
          y: clientY - top,
        });
      }}
      onMouseLeave={handleDragAreaMouseLeave}
      onMouseMove={handleDragAreaMouseMove}
      onMouseUp={handleDragAreaMouseUp}
      sx={{ position: 'relative', ...dragAreaDraggingSx }}
    >
      {floatingNetworkInterface}
      <MUIBox
        sx={{
          display: 'flex',
          flexDirection: 'column',

          '& > :not(:first-child, :nth-child(3))': {
            marginTop: '1em',
          },
        }}
      >
        <MUIDataGrid
          autoHeight
          columns={createNetworkInterfaceTableColumns((row) => {
            setNetworkInterfaceHeld(row);
          }, networkInterfaceInputMap)}
          disableColumnMenu
          disableSelectionOnClick
          getRowId={({ networkInterfaceUUID }) => networkInterfaceUUID}
          hideFooter
          rows={networkInterfaces}
          sx={{
            color: GREY,

            [`& .${muiIconButtonClasses.root}`]: {
              color: 'inherit',
            },

            [`& .${muiGridClasses.cell}:focus`]: {
              outline: 'none',
            },
          }}
        />
        <FlexBox
          row
          sx={{
            '& > :first-child': {
              alignSelf: 'start',
              marginTop: '.7em',
            },

            '& > :last-child': {
              flexGrow: 1,
            },
          }}
        >
          <IconButton
            disabled={isDisableAddNetworkButton}
            onClick={createNetwork}
          >
            <MUIAddIcon />
          </IconButton>
          <MUIBox
            sx={{
              alignItems: 'strech',
              display: 'flex',
              flexDirection: 'row',
              overflowX: 'auto',
              paddingLeft: '.3em',

              '& > div': {
                marginBottom: '.8em',
                marginTop: '.4em',
                minWidth: '13em',
                width: '25%',
              },

              '& > :not(:first-child)': {
                marginLeft: '1em',
              },
            }}
          >
            {networkInputs.map((networkInput, networkIndex) => {
              const { inputUUID } = networkInput;

              return (
                <NetworkForm
                  key={`network-${inputUUID}`}
                  {...{
                    createDropMouseUpHandler,
                    getNetworkTypeCount,
                    inputTests,
                    networkIndex,
                    networkInput,
                    networkInputs,
                    networkInterfaceInputMap,
                    optionalNetworkInputsLength,
                    setNetworkInputs,
                    setNetworkInterfaceInputMap,
                    testAllInputs,
                    toggleSubmitDisabled,
                  }}
                />
              );
            })}
          </MUIBox>
        </FlexBox>
        <FlexBox
          sm="row"
          sx={{ marginTop: '.2em', '& > :last-child': { flexGrow: 1 } }}
        >
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id="network-init-gateway"
                inputLabelProps={{ isNotifyRequired: true }}
                onChange={({ target: { value } }) => {
                  const isLocalValid = testInput({
                    inputs: { [INPUT_TEST_IDS.gateway]: { value } },
                    tests: inputTests,
                  });

                  toggleSubmitDisabled?.call(
                    null,
                    isLocalValid && testAllInputs(INPUT_TEST_IDS.gateway),
                  );
                }}
                label="Gateway"
              />
            }
            ref={gatewayInputRef}
          />
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id="network-init-dns-csv"
                inputLabelProps={{ isNotifyRequired: true }}
                onChange={({ target: { value } }) => {
                  const isLocalValid = testInput({
                    inputs: { [INPUT_TEST_IDS.dnsCSV]: { value } },
                    tests: inputTests,
                  });

                  toggleSubmitDisabled?.call(
                    null,
                    isLocalValid && testAllInputs(INPUT_TEST_IDS.dnsCSV),
                  );
                }}
                label="Domain name server(s)"
              />
            }
            ref={dnsCSVInputRef}
          />
        </FlexBox>
        <MessageGroup
          count={
            BASE_INPUT_COUNT + networkInputs.length * PER_NETWORK_INPUT_COUNT
          }
          defaultMessageType="warning"
          ref={messageGroupRef}
        />
      </MUIBox>
    </MUIBox>
  );
});

NetworkInitForm.defaultProps = { toggleSubmitDisabled: undefined };
NetworkInitForm.displayName = 'NetworkInitForm';

export type {
  NetworkInitFormForwardRefContent,
  NetworkInput,
  NetworkInterfaceInputMap,
};

export default NetworkInitForm;
