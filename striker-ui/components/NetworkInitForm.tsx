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
import { Netmask } from 'netmask';
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
import getFilled from '../lib/getFilled';
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
import { createTestInputFunction, testNotBlank } from '../lib/test_input';
import { InputTestBatches, InputTestInputs } from '../types/TestInputFunction';
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

const MAX_INTERFACES_PER_NETWORK = 2;
const IT_IDS = {
  dnsCSV: 'domainNameServerCSV',
  gateway: 'gateway',
  networkInterfaces: (prefix: string) => `${prefix}Interface`,
  networkIPAddress: (prefix: string) => `${prefix}IPAddress`,
  networkName: (prefix: string) => `${prefix}Name`,
  networkSubnetMask: (prefix: string) => `${prefix}SubnetMask`,
  networkSubnetConflict: (prefix: string) => `${prefix}NetworkSubnetConflict`,
};

const NETWORK_INTERFACE_TEMPLATE = Array.from(
  { length: MAX_INTERFACES_PER_NETWORK },
  (unused, index) => index + 1,
);

const createInputTestPrefix = (uuid: string) => `network${uuid}`;

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
  networkIndex: number;
  networkInput: NetworkInput;
  networkInterfaceInputMap: NetworkInterfaceInputMap;
  optionalNetworkInputsLength: number;
  setNetworkInputs: Dispatch<SetStateAction<NetworkInput[]>>;
  setNetworkInterfaceInputMap: Dispatch<
    SetStateAction<NetworkInterfaceInputMap>
  >;
  testInputSeparate: (id: string, input: InputTestInputs[string]) => void;
}> = ({
  createDropMouseUpHandler,
  getNetworkTypeCount,
  networkIndex,
  networkInput,
  networkInterfaceInputMap,
  optionalNetworkInputsLength,
  setNetworkInputs,
  setNetworkInterfaceInputMap,
  testInputSeparate,
}) => {
  const theme = useTheme();
  const breakpointMedium = useMediaQuery(theme.breakpoints.up('md'));
  const breakpointLarge = useMediaQuery(theme.breakpoints.up('lg'));

  const ipAddressInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const subnetMaskInputRef = useRef<InputForwardedRefContent<'string'>>({});

  const { inputUUID, interfaces, ipAddress, subnetMask, type } = networkInput;

  const inputTestPrefix = useMemo(
    () => createInputTestPrefix(inputUUID),
    [inputUUID],
  );
  const interfacesInputTestId = useMemo(
    () => IT_IDS.networkInterfaces(inputTestPrefix),
    [inputTestPrefix],
  );
  const ipAddressInputTestId = useMemo(
    () => IT_IDS.networkIPAddress(inputTestPrefix),
    [inputTestPrefix],
  );
  const subnetMaskInputTestId = useMemo(
    () => IT_IDS.networkSubnetMask(inputTestPrefix),
    [inputTestPrefix],
  );
  const isNetworkOptional = useMemo(
    () => networkIndex < optionalNetworkInputsLength,
    [networkIndex, optionalNetworkInputsLength],
  );

  useEffect(() => {
    const { ipAddressInputRef: ipRef, subnetMaskInputRef: maskRef } =
      networkInput;

    if (ipRef !== ipAddressInputRef || maskRef !== subnetMaskInputRef) {
      networkInput.ipAddressInputRef = ipAddressInputRef;
      networkInput.subnetMaskInputRef = subnetMaskInputRef;

      setNetworkInputs((previous) => [...previous]);
    }
  }, [networkInput, setNetworkInputs]);

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

              setNetworkInputs((previous) => [...previous]);
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
                onMouseUp={(...args) => {
                  createDropMouseUpHandler
                    ?.call(null, interfaces, networkInterfaceIndex)
                    ?.call(null, ...args);

                  testInputSeparate(interfacesInputTestId, {
                    value: getFilled(interfaces).length,
                  });
                }}
              >
                {networkInterface ? (
                  <BriefNetworkInterface
                    key={`network-interface-${networkInterfaceUUID}`}
                    networkInterface={networkInterface}
                    onClose={() => {
                      interfaces[networkInterfaceIndex] = undefined;
                      networkInterfaceInputMap[networkInterfaceUUID].isApplied =
                        false;

                      setNetworkInterfaceInputMap((previous) => ({
                        ...previous,
                      }));
                      testInputSeparate(interfacesInputTestId, {
                        value: getFilled(interfaces).length,
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
                testInputSeparate(ipAddressInputTestId, { value });
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
                testInputSeparate(subnetMaskInputTestId, { value });
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

  const setMessage = useCallback(
    (key: string, message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, key, message),
    [],
  );
  const setDomainNameServerCSVInputMessage = useCallback(
    (message?: Message) => setMessage(IT_IDS.dnsCSV, message),
    [setMessage],
  );
  const setGatewayInputMessage = useCallback(
    (message?: Message) => setMessage(IT_IDS.gateway, message),
    [setMessage],
  );
  const testSubnetConflict = useCallback(
    (
      changedIP = '',
      changedMask = '',
      {
        onConflict,
        onNoConflict,
        skipUUID,
      }: {
        onConflict?: (
          otherInput: Pick<NetworkInput, 'inputUUID' | 'name'>,
        ) => void;
        onNoConflict?: (otherInput: Pick<NetworkInput, 'inputUUID'>) => void;
        skipUUID?: string;
      },
    ) => {
      let changedSubnet: Netmask | undefined;

      try {
        changedSubnet = new Netmask(`${changedIP}/${changedMask}`);
        // eslint-disable-next-line no-empty
      } catch (netmaskError) {}

      return networkInputs.every(
        ({ inputUUID, ipAddressInputRef, name, subnetMaskInputRef }) => {
          if (inputUUID === skipUUID) {
            return true;
          }

          const otherIP = ipAddressInputRef?.current.getValue?.call(null);
          const otherMask = subnetMaskInputRef?.current.getValue?.call(null);

          let isConflict = false;

          try {
            const otherSubnet = new Netmask(`${otherIP}/${otherMask}`);

            isConflict =
              otherSubnet.contains(changedIP) ||
              (changedSubnet !== undefined &&
                changedSubnet.contains(String(otherIP)));

            // eslint-disable-next-line no-empty
          } catch (netmaskError) {}

          if (isConflict) {
            onConflict?.call(null, { inputUUID, name });
          } else {
            onNoConflict?.call(null, { inputUUID });
          }

          return !isConflict;
        },
      );
    },
    [networkInputs],
  );

  const inputTests: InputTestBatches = useMemo(() => {
    const tests: InputTestBatches = {
      [IT_IDS.dnsCSV]: {
        defaults: {
          getValue: () => dnsCSVInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setDomainNameServerCSVInputMessage();
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
      [IT_IDS.gateway]: {
        defaults: {
          getValue: () => gatewayInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setGatewayInputMessage();
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

    networkInputs.forEach(
      ({
        inputUUID,
        interfaces,
        ipAddressInputRef,
        name,
        subnetMaskInputRef,
      }) => {
        const inputTestPrefix = createInputTestPrefix(inputUUID);
        const inputTestIDIPAddress = IT_IDS.networkIPAddress(inputTestPrefix);
        const inputTestIDSubnetMask = IT_IDS.networkSubnetMask(inputTestPrefix);

        const setNetworkIPAddressInputMessage = (message?: Message) =>
          setMessage(inputTestIDIPAddress, message);
        const setNetworkSubnetMaskInputMessage = (message?: Message) =>
          setMessage(inputTestIDSubnetMask, message);
        const setNetworkSubnetConflict = (
          uuid: string,
          otherUUID: string,
          message?: Message,
        ) => {
          const id = `${IT_IDS.networkSubnetConflict(
            inputTestPrefix,
          )}-${otherUUID}`;
          const reverseID = `${IT_IDS.networkSubnetConflict(
            createInputTestPrefix(otherUUID),
          )}-${uuid}`;

          setMessage(
            messageGroupRef.current.exists?.call(null, reverseID)
              ? reverseID
              : id,
            message,
          );
        };
        const testNetworkSubnetConflictWithDefaults = ({
          ip = ipAddressInputRef?.current.getValue?.call(null),
          mask = subnetMaskInputRef?.current.getValue?.call(null),
        }: {
          ip?: string;
          mask?: string;
        }) =>
          testSubnetConflict(ip, mask, {
            onConflict: ({ inputUUID: otherUUID, name: otherName }) => {
              setNetworkSubnetConflict(inputUUID, otherUUID, {
                children: `"${name}" and "${otherName}" cannot be in the same subnet.`,
              });
            },
            onNoConflict: ({ inputUUID: otherUUID }) => {
              setNetworkSubnetConflict(inputUUID, otherUUID);
            },
            skipUUID: inputUUID,
          });

        tests[IT_IDS.networkInterfaces(inputTestPrefix)] = {
          defaults: { getValue: () => getFilled(interfaces).length },
          tests: [{ test: ({ value }) => (value as number) > 0 }],
        };
        tests[inputTestIDIPAddress] = {
          defaults: {
            getValue: () => ipAddressInputRef?.current.getValue?.call(null),
            onSuccess: () => {
              setNetworkIPAddressInputMessage();
            },
          },
          tests: [
            {
              onFailure: () => {
                setNetworkIPAddressInputMessage({
                  children: `IP address in ${name} must be a valid IPv4 address.`,
                });
              },
              test: ({ value }) => REP_IPV4.test(value as string),
            },
            {
              test: ({ value }) =>
                testNetworkSubnetConflictWithDefaults({ ip: value as string }),
            },
            { test: testNotBlank },
          ],
        };
        tests[IT_IDS.networkName(inputTestPrefix)] = {
          defaults: { value: name },
          tests: [{ test: testNotBlank }],
        };
        tests[IT_IDS.networkSubnetMask(inputTestPrefix)] = {
          defaults: {
            getValue: () => subnetMaskInputRef?.current.getValue?.call(null),
            onSuccess: () => {
              setNetworkSubnetMaskInputMessage();
            },
          },
          tests: [
            {
              onFailure: () => {
                setNetworkSubnetMaskInputMessage({
                  children: `Subnet mask in ${name} must be a valid IPv4 address.`,
                });
              },
              test: ({ value }) => REP_IPV4.test(value as string),
            },
            {
              test: ({ value }) =>
                testNetworkSubnetConflictWithDefaults({
                  mask: value as string,
                }),
            },
            { test: testNotBlank },
          ],
        };
      },
    );

    return tests;
  }, [
    networkInputs,
    setDomainNameServerCSVInputMessage,
    setGatewayInputMessage,
    setMessage,
    testSubnetConflict,
  ]);
  const testInput = useMemo(
    () => createTestInputFunction(inputTests),
    [inputTests],
  );

  const testAllInputs = useCallback(
    (...excludeTestIds: string[]) =>
      testInput({ excludeTestIds, isIgnoreOnCallbacks: true }),
    [testInput],
  );
  const testInputSeparate = useCallback(
    (id: string, input: InputTestInputs[string]) => {
      const isLocalValid = testInput({
        inputs: { [id]: input },
      });
      toggleSubmitDisabled?.call(null, isLocalValid && testAllInputs(id));
    },
    [testInput, testAllInputs, toggleSubmitDisabled],
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
                    networkIndex,
                    networkInput,
                    networkInterfaceInputMap,
                    optionalNetworkInputsLength,
                    setNetworkInputs,
                    setNetworkInterfaceInputMap,
                    testInputSeparate,
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
                  testInputSeparate(IT_IDS.gateway, { value });
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
                  testInputSeparate(IT_IDS.dnsCSV, { value });
                }}
                label="Domain name server(s)"
              />
            }
            ref={dnsCSVInputRef}
          />
        </FlexBox>
        <MessageGroup defaultMessageType="warning" ref={messageGroupRef} />
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
