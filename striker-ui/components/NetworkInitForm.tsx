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
  Close as MUICloseIcon,
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
import NETWORK_TYPES from '../lib/consts/NETWORK_TYPES';
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
import { createTestInputFunction, testNotBlank } from '../lib/test_input';
import { BodyText, MonoText, SmallText } from './Text';

type NetworkInput = {
  inputUUID: string;
  interfaces: (NetworkInterfaceOverviewMetadata | undefined)[];
  ipAddress: string;
  ipAddressInputRef?: MutableRefObject<InputForwardedRefContent<'string'>>;
  isRequired?: boolean;
  name?: string;
  subnetMask: string;
  subnetMaskInputRef?: MutableRefObject<InputForwardedRefContent<'string'>>;
  type: string;
  typeCount: number;
};

type NetworkInterfaceInputMap = Record<
  string,
  {
    metadata: NetworkInterfaceOverviewMetadata;
    isApplied?: boolean;
  }
>;

type NetworkInitFormValues = {
  dns?: string;
  gateway?: string;
  gatewayInterface?: string;
  networks: Omit<NetworkInput, 'ipAddressInputRef' | 'subnetMaskInputRef'>[];
};

type NetworkInitFormForwardedRefContent = MessageGroupForwardedRefContent & {
  get?: () => NetworkInitFormValues;
};

type GetNetworkTypeCountFunction = (
  targetType: string,
  options?: {
    inputs?: NetworkInput[] | undefined;
    lastIndex?: number | undefined;
  },
) => number;

type TestInputToToggleSubmitDisabled = (
  options?: Pick<
    TestInputFunctionOptions,
    'excludeTestIds' | 'excludeTestIdsRe' | 'inputs' | 'isContinueOnFailure'
  >,
) => void;

const CLASS_PREFIX = 'NetworkInitForm';
const CLASSES = {
  ifaceNotApplied: `${CLASS_PREFIX}-network-interface-not-applied`,
};
const INITIAL_IFACES = [undefined, undefined];

const MAX_INTERFACES_PER_NETWORK = 2;
const IT_IDS = {
  dnsCSV: 'dns',
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
const MAP_TO_NETWORK_TYPE_DEFAULTS: Record<
  string,
  { ip: (sequence: number | string, postfix?: string) => string; mask: string }
> = {
  bcn: {
    ip: (sequence, postfix = '') => `10.20${sequence}.${postfix}`,
    mask: '255.255.0.0',
  },
  ifn: { ip: () => '', mask: '' },
  mn: { ip: () => '10.199.', mask: '255.255.0.0' },
  sn: {
    ip: (sequence, postfix = '') => `10.10${sequence}.${postfix}`,
    mask: '255.255.0.0',
  },
};

const createInputTestPrefix = (uuid: string) => `network${uuid}`;

const createNetworkInput = ({
  inputUUID = uuidv4(),
  interfaces = [...INITIAL_IFACES],
  ipAddress = '',
  name: initName,
  subnetMask = '',
  type = '',
  typeCount = 0,
  ...rest
}: Partial<NetworkInput> = {}): NetworkInput => {
  let name = initName;

  if (!initName) {
    if (NETWORK_TYPES[type] && typeCount > 0) {
      name = `${NETWORK_TYPES[type]} ${typeCount}`;
    } else {
      name = 'Unknown Network';
    }
  }

  return {
    inputUUID,
    interfaces,
    ipAddress,
    name,
    subnetMask,
    type,
    typeCount,
    ...rest,
  };
};

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
        <MonoText>{value}</MonoText>
      </MUIBox>
    ),
  },
  {
    field: 'networkInterfaceMACAddress',
    flex: 1,
    headerName: 'MAC',
    renderCell: ({ value }) => <MonoText text={value} />,
  },
  {
    field: 'networkInterfaceState',
    flex: 1,
    headerName: 'State',
    renderCell: ({ value }) => {
      const state = String(value);

      return (
        <SmallText
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
      <SmallText text={`${parseFloat(value).toLocaleString()} Mbps`} />
    ),
  },
  {
    field: 'networkInterfaceOrder',
    flex: 1,
    headerName: 'Order',
  },
];

const NetworkForm: FC<{
  allowMigrationNetwork?: boolean;
  createDropMouseUpHandler?: (
    interfaces: (NetworkInterfaceOverviewMetadata | undefined)[],
    interfaceIndex: number,
  ) => MUIBoxProps['onMouseUp'];
  getNetworkTypeCount: GetNetworkTypeCountFunction;
  hostDetail?: Partial<Pick<APIHostDetail, 'hostType' | 'sequence'>>;
  networkIndex: number;
  networkInput: NetworkInput;
  networkInterfaceCount: number;
  networkInterfaceInputMap: NetworkInterfaceInputMap;
  removeNetwork: (index: number) => void;
  setMessageRe: (re: RegExp, message?: Message) => void;
  setNetworkInputs: Dispatch<SetStateAction<NetworkInput[]>>;
  setNetworkInterfaceInputMap: Dispatch<
    SetStateAction<NetworkInterfaceInputMap>
  >;
  testInput: (options?: TestInputFunctionOptions) => boolean;
  testInputToToggleSubmitDisabled: TestInputToToggleSubmitDisabled;
}> = ({
  allowMigrationNetwork,
  createDropMouseUpHandler,
  getNetworkTypeCount,
  hostDetail: { hostType, sequence } = {},
  networkIndex,
  networkInput,
  networkInterfaceCount,
  networkInterfaceInputMap,
  removeNetwork,
  setMessageRe,
  setNetworkInputs,
  setNetworkInterfaceInputMap,
  testInput,
  testInputToToggleSubmitDisabled,
}) => {
  const theme = useTheme();
  const breakpointMedium = useMediaQuery(theme.breakpoints.up('md'));
  const breakpointLarge = useMediaQuery(theme.breakpoints.up('lg'));

  const ipAddressInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const subnetMaskInputRef = useRef<InputForwardedRefContent<'string'>>({});

  const {
    inputUUID,
    interfaces,
    ipAddress,
    isRequired,
    subnetMask,
    type,
    typeCount,
  } = networkInput;

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
  const subnetConflictInputMessageKeyPrefix = useMemo(
    () => IT_IDS.networkSubnetConflict(inputTestPrefix),
    [inputTestPrefix],
  );

  const isNode = useMemo(() => hostType === 'node', [hostType]);
  const netIfTemplate = useMemo(
    () =>
      !isNode && networkInterfaceCount <= 2 ? [1] : NETWORK_INTERFACE_TEMPLATE,
    [isNode, networkInterfaceCount],
  );
  const netTypeList = useMemo(() => {
    const { bcn, ifn, mn, sn } = NETWORK_TYPES;

    return isNode &&
      networkInterfaceCount >= 8 &&
      (allowMigrationNetwork || type === 'mn')
      ? { bcn, ifn, mn, sn }
      : { bcn, ifn, sn };
  }, [allowMigrationNetwork, isNode, networkInterfaceCount, type]);

  const setIpAndMask = useCallback(
    (nInput: NetworkInput, ip: string, mask: string) => {
      const {
        current: { getIsChangedByUser: getIpModded, setValue: setIp },
      } = ipAddressInputRef;
      const {
        current: { getIsChangedByUser: getMaskModded, setValue: setMask },
      } = subnetMaskInputRef;

      if (!getIpModded?.call(null)) {
        nInput.ipAddress = ip;
        setIp?.call(null, ip);
      }

      if (!getMaskModded?.call(null)) {
        nInput.subnetMask = mask;
        setMask?.call(null, mask);
      }
    },
    [],
  );

  useEffect((): void => {
    if (hostType !== 'striker' || type === 'ifn') return;

    const changedByUser =
      ipAddressInputRef.current.getIsChangedByUser?.call(null);

    if (changedByUser || !Number(sequence)) return;

    ipAddressInputRef.current.setValue?.call(
      null,
      ipAddress.replace(/^((?:\d+\.){3})\d*$/, `$1${sequence}`),
    );
  }, [hostType, ipAddress, sequence, type]);

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
          isReadOnly={isRequired}
          inputLabelProps={{ isNotifyRequired: true }}
          label="Network name"
          selectItems={Object.entries(netTypeList).map(
            ([networkType, networkTypeName]) => {
              let count = getNetworkTypeCount(networkType, {
                lastIndex: networkIndex,
              });

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

              const networkTypeCount = getNetworkTypeCount(networkType, {
                lastIndex: networkIndex,
              });

              networkInput.typeCount = networkTypeCount;
              networkInput.name = `${NETWORK_TYPES[networkType]} ${networkTypeCount}`;

              const networkTypeDefaults =
                MAP_TO_NETWORK_TYPE_DEFAULTS[networkType];

              if (networkTypeDefaults) {
                const { ip, mask } = networkTypeDefaults;

                let postfix: string | undefined;

                if (hostType === 'striker' && networkType === 'bcn') {
                  postfix = '4.';
                }

                setIpAndMask(networkInput, ip(networkTypeCount, postfix), mask);
              }

              setNetworkInputs((previous) => [...previous]);
            },
            renderValue: breakpointLarge
              ? undefined
              : (value) => `${String(value).toUpperCase()} ${typeCount}`,
            value: type,
          }}
        />
        {!isRequired && (
          <IconButton
            onClick={() => {
              removeNetwork(networkIndex);
            }}
            sx={{
              padding: '.2em',
              position: 'absolute',
              right: '-9px',
              top: '-4px',
            }}
          >
            <MUICloseIcon fontSize="small" />
          </IconButton>
        )}
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
        {netIfTemplate.map((linkNumber) => {
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
                  testInputToToggleSubmitDisabled({
                    inputs: {
                      [interfacesInputTestId]: {
                        isIgnoreOnCallbacks: false,
                      },
                    },
                    isContinueOnFailure: true,
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
                      testInputToToggleSubmitDisabled({
                        inputs: {
                          [interfacesInputTestId]: {
                            isIgnoreOnCallbacks: false,
                          },
                        },
                        isContinueOnFailure: true,
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
              inputProps={{
                onBlur: ({ target: { value } }) => {
                  testInput({ inputs: { [ipAddressInputTestId]: { value } } });
                },
              }}
              inputLabelProps={{ isNotifyRequired: true }}
              label="IP address"
              onChange={({ target: { value } }) => {
                testInputToToggleSubmitDisabled({
                  inputs: { [ipAddressInputTestId]: { value } },
                });
                setMessageRe(
                  RegExp(
                    `(?:^(?:${ipAddressInputTestId}|${subnetConflictInputMessageKeyPrefix})|${inputUUID}$)`,
                  ),
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
              inputProps={{
                onBlur: ({ target: { value } }) => {
                  testInput({ inputs: { [subnetMaskInputTestId]: { value } } });
                },
              }}
              inputLabelProps={{ isNotifyRequired: true }}
              label="Subnet mask"
              onChange={({ target: { value } }) => {
                testInputToToggleSubmitDisabled({
                  inputs: { [subnetMaskInputTestId]: { value } },
                });
                setMessageRe(
                  RegExp(
                    `(?:^(?:${subnetMaskInputTestId}|${subnetConflictInputMessageKeyPrefix})|${inputUUID}$)`,
                  ),
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
  allowMigrationNetwork: true,
  createDropMouseUpHandler: undefined,
  hostDetail: undefined,
};

const NetworkInitForm = forwardRef<
  NetworkInitFormForwardedRefContent,
  {
    expectHostDetail?: boolean;
    hostDetail?: APIHostDetail;
    hostSequence?: string;
    mini?: boolean;
    toggleSubmitDisabled?: (testResult: boolean) => void;
  }
>(
  (
    {
      expectHostDetail = false,
      hostDetail,
      hostSequence,
      mini,
      toggleSubmitDisabled,
    },
    ref,
  ) => {
    let hostType: string | undefined;
    let hostUUID = 'local';
    let sequence = hostSequence;

    if (!expectHostDetail) {
      hostType = 'striker';
    } else if (hostDetail) {
      ({ hostType, hostUUID, sequence } = hostDetail);
    }

    const initRequiredNetworks: NetworkInput[] = useMemo(() => {
      const result: NetworkInput[] = [];

      if (hostType === 'striker') {
        const ipAddress = sequence ? `10.201.4.${sequence}` : '10.201.4.';

        result.push(
          createNetworkInput({
            ipAddress,
            isRequired: true,
            subnetMask: '255.255.0.0',
            type: 'bcn',
            typeCount: 1,
          }),
          createNetworkInput({
            isRequired: true,
            type: 'ifn',
            typeCount: 1,
          }),
        );

        return result;
      }

      result.push(
        createNetworkInput({
          ipAddress: '10.201.',
          isRequired: true,
          subnetMask: '255.255.0.0',
          type: 'bcn',
          typeCount: 1,
        }),
        createNetworkInput({
          isRequired: true,
          type: 'ifn',
          typeCount: 1,
        }),
        createNetworkInput({
          ipAddress: '10.101.',
          isRequired: true,
          subnetMask: '255.255.0.0',
          type: 'sn',
          typeCount: 1,
        }),
      );

      return result;
    }, [hostType, sequence]);

    const requiredNetworks = useMemo<Partial<Record<NetworkType, number>>>(
      () =>
        hostType === 'node' ? { bcn: 1, ifn: 1, sn: 1 } : { bcn: 1, ifn: 1 },
      [hostType],
    );

    const [dragMousePosition, setDragMousePosition] = useState<{
      x: number;
      y: number;
    }>({ x: 0, y: 0 });
    const [networkInterfaceInputMap, setNetworkInterfaceInputMap] =
      useState<NetworkInterfaceInputMap>({});
    const [networkInputs, setNetworkInputs] =
      useState<NetworkInput[]>(initRequiredNetworks);
    const [networkInterfaceHeld, setNetworkInterfaceHeld] = useState<
      NetworkInterfaceOverviewMetadata | undefined
    >();
    const [gatewayInterface, setGatewayInterface] = useState<string>('');

    const dnsCSVInputRef = useRef<InputForwardedRefContent<'string'>>({});
    const gatewayInputRef = useRef<InputForwardedRefContent<'string'>>({});
    /** Avoid state here to prevent triggering multiple renders when reading
     * host detail. */
    const readHostDetailRef = useRef<boolean>(true);
    const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

    const {
      data: networkInterfaces = [],
      isLoading: isLoadingNetworkInterfaces,
    } = periodicFetch<NetworkInterfaceOverviewMetadata[]>(
      `${API_BASE_URL}/init/network-interface/${hostUUID}`,
      {
        refreshInterval: 2000,
        onSuccess: (data) => {
          const map = data.reduce<NetworkInterfaceInputMap>(
            (result, metadata) => {
              const { networkInterfaceUUID } = metadata;

              result[networkInterfaceUUID] = networkInterfaceInputMap[
                networkInterfaceUUID
              ] ?? { metadata };

              return result;
            },
            {},
          );

          setNetworkInterfaceInputMap(map);
        },
      },
    );

    const isDisableAddNetworkButton: boolean = useMemo(
      () =>
        networkInputs.length >= networkInterfaces.length ||
        Object.values(networkInterfaceInputMap).every(
          ({ isApplied }) => isApplied,
        ) ||
        (hostType === 'node' && networkInterfaces.length <= 6),
      [hostType, networkInputs, networkInterfaces, networkInterfaceInputMap],
    );
    const isLoadingHostDetail: boolean = useMemo(
      () => expectHostDetail && !hostDetail,
      [expectHostDetail, hostDetail],
    );
    /**
     * Allow user to add migration network only if none exists.
     */
    const allowMigrationNetwork: boolean = useMemo(
      () => networkInputs.every(({ type }) => type !== 'mn'),
      [networkInputs],
    );

    const setMessage = useCallback(
      (key: string, message?: Message) =>
        messageGroupRef.current.setMessage?.call(null, key, message),
      [],
    );
    const setMessageRe = useCallback(
      (re: RegExp, message?: Message) =>
        messageGroupRef.current.setMessageRe?.call(null, re, message),
      [],
    );
    const setDnsInputMessage = useCallback(
      (message?: Message) => setMessage(IT_IDS.dnsCSV, message),
      [setMessage],
    );
    const setGatewayInputMessage = useCallback(
      (message?: Message) => setMessage(IT_IDS.gateway, message),
      [setMessage],
    );
    const subnetContains = useCallback(
      ({
        fn = 'every',
        ip = '',
        mask = '',
        isNegateMatch = fn === 'every',
        onMatch,
        onMiss,
        skipUUID,
      }: {
        fn?: Extract<keyof Array<NetworkInput>, 'every' | 'some'>;
        ip?: string;
        isNegateMatch?: boolean;
        mask?: string;
        onMatch?: (otherInput: NetworkInput) => void;
        onMiss?: (otherInput: NetworkInput) => void;
        skipUUID?: string;
      }) => {
        const skipReturn = fn === 'every';
        const match = (
          a: Netmask,
          { b, bIP = '' }: { aIP?: string; b?: Netmask; bIP?: string },
        ) => a.contains(b ?? bIP) || (b !== undefined && b.contains(a));

        let subnet: Netmask | undefined;

        try {
          subnet = new Netmask(`${ip}/${mask}`);
          // TODO: find a way to express the netmask creation error
          // eslint-disable-next-line no-empty
        } catch (netmaskError) {}

        return networkInputs[fn]((networkInput) => {
          const { inputUUID, ipAddressInputRef, subnetMaskInputRef } =
            networkInput;

          if (inputUUID === skipUUID) {
            return skipReturn;
          }

          const otherIP = ipAddressInputRef?.current.getValue?.call(null);
          const otherMask = subnetMaskInputRef?.current.getValue?.call(null);

          let isMatch = false;

          try {
            const otherSubnet = new Netmask(`${otherIP}/${otherMask}`);

            isMatch = match(otherSubnet, { b: subnet, bIP: ip });

            // TODO: find a way to express the netmask creation error
            // eslint-disable-next-line no-empty
          } catch (netmaskError) {}

          if (isMatch) {
            onMatch?.call(null, networkInput);
          } else {
            onMiss?.call(null, networkInput);
          }

          return isNegateMatch ? !isMatch : isMatch;
        });
      },
      [networkInputs],
    );

    const inputTests: InputTestBatches = useMemo(() => {
      const tests: InputTestBatches = {
        [IT_IDS.dnsCSV]: {
          defaults: {
            getValue: () => dnsCSVInputRef.current.getValue?.call(null),
            onSuccess: () => {
              setDnsInputMessage();
            },
          },
          isRequired: true,
          tests: [
            {
              onFailure: () => {
                setDnsInputMessage({
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
          isRequired: true,
          tests: [
            {
              onFailure: () => {
                setGatewayInputMessage({
                  children: 'Gateway should be a valid IPv4 address.',
                });
              },
              test: ({ value }) => REP_IPV4.test(value as string),
            },
            {
              test: ({ value }) => {
                let isDistinctIP = true;

                const isIPInOneNetwork = subnetContains({
                  fn: 'some',
                  ip: value as string,
                  onMatch: ({ ipAddress, name, type, typeCount }) => {
                    if (value === ipAddress) {
                      isDistinctIP = false;

                      setGatewayInputMessage({
                        children: `Gateway cannot be the same as IP address in ${name}.`,
                      });

                      return;
                    }

                    setGatewayInterface(`${type}${typeCount}`);
                  },
                });

                if (!isIPInOneNetwork) {
                  setGatewayInputMessage({
                    children: "Gateway must be in one network's subnet.",
                  });
                }

                return isIPInOneNetwork && isDistinctIP;
              },
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
          const inputTestIDIfaces = IT_IDS.networkInterfaces(inputTestPrefix);
          const inputTestIDIPAddress = IT_IDS.networkIPAddress(inputTestPrefix);
          const inputTestIDSubnetMask =
            IT_IDS.networkSubnetMask(inputTestPrefix);

          const setNetworkIfacesInputMessage = (message?: Message) =>
            setMessage(inputTestIDIfaces, message);
          const setNetworkIPAddressInputMessage = (message?: Message) =>
            setMessage(inputTestIDIPAddress, message);
          const setNetworkSubnetMaskInputMessage = (message?: Message) =>
            setMessage(inputTestIDSubnetMask, message);
          const setNetworkSubnetConflictInputMessage = (
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
            subnetContains({
              ip,
              mask,
              onMatch: ({ inputUUID: otherUUID, name: otherName }) => {
                setNetworkSubnetConflictInputMessage(inputUUID, otherUUID, {
                  children: `"${name}" and "${otherName}" cannot be in the same subnet.`,
                });
              },
              onMiss: ({ inputUUID: otherUUID }) => {
                setNetworkSubnetConflictInputMessage(inputUUID, otherUUID);
              },
              skipUUID: inputUUID,
            });

          tests[inputTestIDIfaces] = {
            defaults: {
              getCompare: () => interfaces.map((iface) => iface !== undefined),
              onSuccess: () => {
                setNetworkIfacesInputMessage();
              },
            },
            isRequired: true,
            tests: [
              {
                onFailure: () => {
                  setNetworkIfacesInputMessage({
                    children: `${name} must have at least 1 interface.`,
                  });
                },
                test: ({ compare }) =>
                  (compare as boolean[]).some((ifaceSet) => ifaceSet),
              },
              {
                onFailure: () => {
                  setNetworkIfacesInputMessage({
                    children: `${name} must have a Link 1 interface.`,
                  });
                },
                test: ({ compare: [iface1Exists, iface2Exists] }) =>
                  !(iface2Exists && !iface1Exists),
              },
            ],
          };
          tests[inputTestIDIPAddress] = {
            defaults: {
              getValue: () => ipAddressInputRef?.current.getValue?.call(null),
              onSuccess: () => {
                setNetworkIPAddressInputMessage();
              },
            },
            isRequired: true,
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
                  testNetworkSubnetConflictWithDefaults({
                    ip: value as string,
                  }),
              },
              { test: testNotBlank },
            ],
          };
          tests[IT_IDS.networkName(inputTestPrefix)] = {
            defaults: { value: name },
            isRequired: true,
            tests: [{ test: testNotBlank }],
          };
          tests[inputTestIDSubnetMask] = {
            defaults: {
              getValue: () => subnetMaskInputRef?.current.getValue?.call(null),
              onSuccess: () => {
                setNetworkSubnetMaskInputMessage();
              },
            },
            isRequired: true,
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
      setDnsInputMessage,
      setGatewayInputMessage,
      setMessage,
      subnetContains,
    ]);
    const testInput = useMemo(
      () => createTestInputFunction(inputTests),
      [inputTests],
    );

    const testInputToToggleSubmitDisabled: TestInputToToggleSubmitDisabled =
      useCallback(
        (options) => {
          toggleSubmitDisabled?.call(
            null,
            testInput({
              isIgnoreOnCallbacks: true,
              isTestAll: true,

              ...options,
            }),
          );
        },
        [testInput, toggleSubmitDisabled],
      );
    const clearNetworkInterfaceHeld = useCallback(() => {
      setNetworkInterfaceHeld(undefined);
    }, []);
    const createNetwork = useCallback(
      (args: Partial<NetworkInput> = {}) => {
        networkInputs.unshift(createNetworkInput(args));

        toggleSubmitDisabled?.call(null, false);
        setNetworkInputs([...networkInputs]);
      },
      [networkInputs, toggleSubmitDisabled],
    );
    const removeNetwork = useCallback(
      (networkIndex: number) => {
        const [{ inputUUID, interfaces }] = networkInputs.splice(
          networkIndex,
          1,
        );

        interfaces.forEach((iface) => {
          if (iface === undefined) {
            return;
          }

          const { networkInterfaceUUID } = iface;

          networkInterfaceInputMap[networkInterfaceUUID].isApplied = false;
        });

        testInputToToggleSubmitDisabled({
          excludeTestIdsRe: RegExp(inputUUID),
        });
        setNetworkInputs([...networkInputs]);
        setNetworkInterfaceInputMap((previous) => ({
          ...previous,
        }));
      },
      [
        networkInputs,
        networkInterfaceInputMap,
        testInputToToggleSubmitDisabled,
      ],
    );
    const getNetworkTypeCount: GetNetworkTypeCountFunction = useCallback(
      (
        targetType: string,
        {
          inputs = networkInputs,
          lastIndex = 0,
        }: {
          inputs?: NetworkInput[];
          lastIndex?: number;
        } = {},
      ) => {
        let count = 0;

        for (let index = inputs.length - 1; index >= lastIndex; index -= 1) {
          if (inputs[index].type === targetType) {
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
      () =>
        networkInterfaceHeld ? { cursor: 'grabbing', userSelect: 'none' } : {},
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
      if (
        [
          Object.keys(networkInterfaceInputMap).length > 0,
          expectHostDetail,
          hostDetail,
          readHostDetailRef.current,
          dnsCSVInputRef.current,
          gatewayInputRef.current,
        ].every((condition) => Boolean(condition))
      ) {
        readHostDetailRef.current = false;

        const {
          dns: pDns,
          gateway: pGateway,
          gatewayInterface: pGatewayInterface,
          networks: pNetworks,
        } = hostDetail as APIHostDetail;

        if (
          [pDns, pGateway, pGatewayInterface, pNetworks].some(
            (condition) => !condition,
          )
        ) {
          return;
        }

        dnsCSVInputRef.current.setValue?.call(null, pDns);
        gatewayInputRef.current.setValue?.call(null, pGateway);

        const applied: string[] = [];
        const inputs = Object.values(pNetworks as APIHostNetworkList).reduce<
          NetworkInput[]
        >((previous, { ip, link1Uuid, link2Uuid = '', subnetMask, type }) => {
          const typeCount = getNetworkTypeCount(type, { inputs: previous }) + 1;
          const isRequired = requiredNetworks[type] === typeCount;

          const name = `${NETWORK_TYPES[type]} ${typeCount}`;

          applied.push(link1Uuid, link2Uuid);

          previous.push({
            inputUUID: uuidv4(),
            interfaces: [
              networkInterfaceInputMap[link1Uuid]?.metadata,
              networkInterfaceInputMap[link2Uuid]?.metadata,
            ],
            ipAddress: ip,
            isRequired,
            name,
            subnetMask,
            type,
            typeCount,
          });

          return previous;
        }, []);

        setGatewayInterface(pGatewayInterface as string);

        setNetworkInterfaceInputMap((previous) => {
          const result = { ...previous };

          applied.forEach((uuid) => {
            if (result[uuid]) {
              result[uuid].isApplied = true;
            }
          });

          return result;
        });

        setNetworkInputs(inputs);

        testInputToToggleSubmitDisabled();
      }
    }, [
      expectHostDetail,
      getNetworkTypeCount,
      hostDetail,
      networkInterfaceInputMap,
      requiredNetworks,
      testInputToToggleSubmitDisabled,
    ]);

    useEffect((): void => {
      if (mini) {
        setNetworkInputs((previous) =>
          previous.map<NetworkInput>((value) => {
            const shallow = { ...value };

            shallow.isRequired = false;

            return shallow;
          }),
        );

        return;
      }

      setNetworkInputs((previous) =>
        previous.map<NetworkInput>((value) => {
          const shallow = { ...value };

          const found = initRequiredNetworks.find(
            (current) =>
              shallow.type === current.type &&
              shallow.typeCount === current.typeCount,
          );

          if (found) {
            shallow.isRequired = true;
          }

          return shallow;
        }),
      );
    }, [initRequiredNetworks, mini]);

    useImperativeHandle(
      ref,
      () => ({
        ...messageGroupRef.current,
        get: () => ({
          dns: dnsCSVInputRef.current.getValue?.call(null),
          gateway: gatewayInputRef.current.getValue?.call(null),
          gatewayInterface,
          networks: networkInputs.map(
            ({
              inputUUID,
              interfaces,
              ipAddressInputRef,
              name,
              subnetMaskInputRef,
              type,
              typeCount,
            }) => ({
              inputUUID,
              interfaces,
              ipAddress: ipAddressInputRef?.current.getValue?.call(null) ?? '',
              name,
              subnetMask:
                subnetMaskInputRef?.current.getValue?.call(null) ?? '',
              type,
              typeCount,
            }),
          ),
        }),
      }),
      [gatewayInterface, networkInputs],
    );

    const networkInputMinWidth = '13em';
    const networkInputWidth = '25%';

    return isLoadingNetworkInterfaces ? (
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
            componentsProps={{
              row: {
                onMouseDown: ({
                  target: {
                    parentElement: {
                      dataset: { id: networkInterfaceUUID = undefined } = {},
                    } = {},
                  } = {},
                }: {
                  target?: { parentElement?: { dataset?: { id?: string } } };
                }) => {
                  if (networkInterfaceUUID) {
                    const { isApplied, metadata } =
                      networkInterfaceInputMap[networkInterfaceUUID];

                    if (!isApplied) {
                      setNetworkInterfaceHeld(metadata);
                    }
                  }
                },
              },
            }}
            disableColumnMenu
            disableSelectionOnClick
            getRowClassName={({ row: { networkInterfaceUUID } }) => {
              const { isApplied } =
                networkInterfaceInputMap[networkInterfaceUUID] ?? false;

              let className = '';

              if (!isApplied) {
                className += ` ${CLASSES.ifaceNotApplied}`;
              }

              return className;
            }}
            getRowId={({ networkInterfaceUUID }) => networkInterfaceUUID}
            hideFooter
            initialState={{
              sorting: {
                sortModel: [{ field: 'networkInterfaceName', sort: 'asc' }],
              },
            }}
            rows={networkInterfaces}
            sx={{
              color: GREY,

              [`& .${muiIconButtonClasses.root}`]: {
                color: 'inherit',
              },

              [`& .${muiGridClasses.cell}:focus`]: {
                outline: 'none',
              },

              [`& .${muiGridClasses.row}.${CLASSES.ifaceNotApplied}:hover`]: {
                cursor: 'grab',

                [`& .${muiGridClasses.cell} p`]: {
                  cursor: 'auto',
                },
              },
            }}
          />
          {!isLoadingHostDetail && (
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
                    minWidth: networkInputMinWidth,
                    width: networkInputWidth,
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
                        allowMigrationNetwork,
                        createDropMouseUpHandler,
                        getNetworkTypeCount,
                        hostDetail: { hostType, sequence },
                        networkIndex,
                        networkInput,
                        networkInterfaceCount: networkInterfaces.length,
                        networkInterfaceInputMap,
                        removeNetwork,
                        setMessageRe,
                        setNetworkInputs,
                        setNetworkInterfaceInputMap,
                        testInput,
                        testInputToToggleSubmitDisabled,
                      }}
                    />
                  );
                })}
              </MUIBox>
            </FlexBox>
          )}
          <FlexBox
            sm="row"
            sx={{
              marginTop: '.2em',

              '& > :not(button)': {
                minWidth: networkInputMinWidth,
                width: { sm: networkInputWidth },
              },
            }}
          >
            <IconButton
              disabled={isDisableAddNetworkButton}
              onClick={() => {
                createNetwork();
              }}
            >
              <MUIAddIcon />
            </IconButton>
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id="network-init-gateway"
                  inputProps={{
                    onBlur: ({ target: { value } }) => {
                      testInput({ inputs: { [IT_IDS.gateway]: { value } } });
                    },
                  }}
                  inputLabelProps={{ isNotifyRequired: true }}
                  onChange={({ target: { value } }) => {
                    testInputToToggleSubmitDisabled({
                      inputs: { [IT_IDS.gateway]: { value } },
                    });
                    setGatewayInputMessage();
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
                  inputProps={{
                    onBlur: ({ target: { value } }) => {
                      testInput({ inputs: { [IT_IDS.dnsCSV]: { value } } });
                    },
                  }}
                  inputLabelProps={{ isNotifyRequired: true }}
                  onChange={({ target: { value } }) => {
                    testInputToToggleSubmitDisabled({
                      inputs: { [IT_IDS.dnsCSV]: { value } },
                    });
                    setDnsInputMessage();
                  }}
                  label="Domain name server(s)"
                />
              }
              ref={dnsCSVInputRef}
            />
          </FlexBox>
          <MessageGroup
            count={1}
            defaultMessageType="warning"
            ref={messageGroupRef}
          />
        </MUIBox>
      </MUIBox>
    );
  },
);

NetworkInitForm.defaultProps = {
  expectHostDetail: false,
  hostDetail: undefined,
  hostSequence: undefined,
  mini: false,
  toggleSubmitDisabled: undefined,
};
NetworkInitForm.displayName = 'NetworkInitForm';

export type {
  NetworkInitFormForwardedRefContent,
  NetworkInitFormValues,
  NetworkInput,
  NetworkInterfaceInputMap,
};

export default NetworkInitForm;
