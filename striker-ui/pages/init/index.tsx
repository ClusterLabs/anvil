import { FC, useEffect, useState } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  iconButtonClasses as muiIconButtonClasses,
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

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { BLUE, GREY, TEXT } from '../../lib/consts/DEFAULT_THEME';

import Decorator from '../../components/Decorator';
import {
  InnerPanel,
  InnerPanelHeader,
  Panel,
  PanelHeader,
} from '../../components/Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../../components/Spinner';
import sumstring from '../../lib/sumstring';
import { BodyText, BodyTextProps, HeaderText } from '../../components/Text';
import OutlinedInputWithLabel from '../../components/OutlinedInputWithLabel';

type NetworkInput = {
  interfaces: NetworkInterfaceOverviewMetadata[];
  ipAddress: string;
  name: string;
  subnetMask: string;
};

type NetworkInterfaceInputMap = Record<
  string,
  {
    isApplied?: boolean;
  }
>;

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

const DataGridCellText: FC<BodyTextProps> = ({
  ...dataGridCellTextRestProps
}) => (
  <BodyText
    {...{
      variant: 'body2',
      ...dataGridCellTextRestProps,
    }}
  />
);

type BriefNetworkInterfaceOptionalProps = {
  onClose?: MUIIconButtonProps['onClick'];
};

const BRIEF_NETWORK_INTERFACE_DEFAULT_PROPS: Required<
  Omit<BriefNetworkInterfaceOptionalProps, 'onClose'>
> &
  Pick<BriefNetworkInterfaceOptionalProps, 'onClose'> = {
  onClose: undefined,
};

const BriefNetworkInterface: FC<
  MUIBoxProps &
    BriefNetworkInterfaceOptionalProps & {
      networkInterface: NetworkInterfaceOverviewMetadata;
    }
> = ({
  networkInterface: { networkInterfaceName, networkInterfaceState },
  onClose,
  sx: rootSx,
  ...restRootProps
}) => (
  <MUIBox
    {...{
      sx: {
        display: 'flex',
        flexDirection: 'row',

        '& > :not(:first-child)': { marginLeft: '.5em' },

        ...rootSx,
      },

      ...restRootProps,
    }}
  >
    <Decorator
      colour={networkInterfaceState === 'up' ? 'ok' : 'off'}
      sx={{ height: 'auto' }}
    />
    <BodyText text={networkInterfaceName} />
    {onClose && (
      <MUIIconButton onClick={onClose} size="small" sx={{ color: GREY }}>
        <MUICloseIcon />
      </MUIIconButton>
    )}
  </MUIBox>
);

BriefNetworkInterface.defaultProps = BRIEF_NETWORK_INTERFACE_DEFAULT_PROPS;

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
        networkInterfaceInputMap[row.networkInterfaceUUID] || false;

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

const NetworkInterfaceList: FC = () => {
  const [dragMousePosition, setDragMousePosition] = useState<{
    x: number;
    y: number;
  }>({ x: 0, y: 0 });
  const [networkInterfaceInputMap, setNetworkInterfaceInputMap] =
    useState<NetworkInterfaceInputMap>({});
  const [networkInputs] = useState<NetworkInput[]>([
    {
      ipAddress: '10.200.1.1',
      name: 'Back-Channel Network 1',
      interfaces: [],
      subnetMask: '255.255.0.0',
    },
    {
      ipAddress: '10.201.1.1',
      name: 'Internet-Facing Network 1',
      interfaces: [],
      subnetMask: '255.255.0.0',
    },
  ]);
  const [networkInterfaceHeld, setNetworkInterfaceHeld] = useState<
    NetworkInterfaceOverviewMetadata | undefined
  >();

  const { data: networkInterfaces = MOCK_NICS, isLoading } = periodicFetch<
    NetworkInterfaceOverviewMetadata[]
  >(`${API_BASE_URL}/network-interface`, {
    refreshInterval: 2000,
    onSuccess: (data) => {
      if (data instanceof Array) {
        const map = data.reduce<NetworkInterfaceInputMap>(
          (reduceContainer, { networkInterfaceUUID }) => {
            reduceContainer[networkInterfaceUUID] =
              networkInterfaceInputMap[networkInterfaceUUID] || {};

            return reduceContainer;
          },
          {},
        );

        setNetworkInterfaceInputMap(map);
      }
    },
  });

  const clearNetworkInterfaceHeld = () => {
    setNetworkInterfaceHeld(undefined);
  };

  let createDropMouseUpHandler: (
    interfaces: NetworkInterfaceOverviewMetadata[],
  ) => MUIBoxProps['onMouseUp'];
  let floatingNetworkInterface: JSX.Element = <></>;
  let handleCreateNetworkMouseUp: MUIBoxProps['onMouseUp'];
  let handlePanelMouseMove: MUIBoxProps['onMouseMove'];

  if (networkInterfaceHeld) {
    const { networkInterfaceUUID } = networkInterfaceHeld;

    createDropMouseUpHandler =
      (interfaces: NetworkInterfaceOverviewMetadata[]) => () => {
        interfaces.push(networkInterfaceHeld);

        networkInterfaceInputMap[networkInterfaceUUID].isApplied = true;
      };

    floatingNetworkInterface = (
      <BriefNetworkInterface
        networkInterface={networkInterfaceHeld}
        sx={{
          left: `calc(${dragMousePosition.x}px - .4em)`,
          position: 'absolute',
          top: `calc(${dragMousePosition.y}px - 2em)`,
          zIndex: 10,
        }}
      />
    );

    handleCreateNetworkMouseUp = () => {
      networkInputs.push({
        ipAddress: '',
        name: '',
        interfaces: [networkInterfaceHeld],
        subnetMask: '',
      });

      networkInterfaceInputMap[networkInterfaceUUID].isApplied = true;
    };

    handlePanelMouseMove = ({ nativeEvent: { clientX, clientY } }) => {
      setDragMousePosition({
        x: clientX,
        y: clientY,
      });
    };
  }

  useEffect(() => {
    const map = networkInterfaces.reduce<NetworkInterfaceInputMap>(
      (reduceContainer, { networkInterfaceUUID }) => {
        reduceContainer[networkInterfaceUUID] =
          networkInterfaceInputMap[networkInterfaceUUID] || {};

        return reduceContainer;
      },
      {},
    );

    setNetworkInterfaceInputMap(map);

    // This block inits the input map for the MOCK_NICS.
    // TODO: remove after testing.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Panel
      onMouseLeave={clearNetworkInterfaceHeld}
      onMouseMove={handlePanelMouseMove}
      onMouseUp={clearNetworkInterfaceHeld}
    >
      <PanelHeader>
        <HeaderText text="Network Interfaces" />
      </PanelHeader>
      {floatingNetworkInterface}
      {isLoading ? (
        <Spinner />
      ) : (
        <MUIBox
          sx={{
            display: 'flex',
            flexDirection: 'column',

            '& > :not(:first-child)': {
              marginTop: '1em',
            },
          }}
        >
          <MUIDataGrid
            autoHeight
            columns={createNetworkInterfaceTableColumns(
              (row, { clientX, clientY }) => {
                setDragMousePosition({
                  x: clientX,
                  y: clientY,
                });
                setNetworkInterfaceHeld(row);
              },
              networkInterfaceInputMap,
            )}
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
          <MUIBox
            sx={{
              display: 'flex',
              flexDirection: 'row',
              overflowX: 'auto',

              '& > *': {
                marginBottom: '1em',
                marginTop: '1em',
              },

              '& > :not(:first-child)': {
                marginLeft: '1em',
              },
            }}
          >
            <MUIBox
              onMouseUp={handleCreateNetworkMouseUp}
              sx={{
                alignItems: 'center',
                borderColor: TEXT,
                borderStyle: 'dashed',
                borderWidth: '4px',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                padding: '.6em',
              }}
            >
              <MUIAddIcon fontSize="large" sx={{ color: GREY }} />
              <BodyText
                text="Drag interfaces here to create a new network."
                sx={{
                  textAlign: 'center',
                }}
              />
            </MUIBox>
            {networkInputs.map(
              ({ interfaces, ipAddress, name, subnetMask }, networkIndex) => (
                <InnerPanel key={`network-input-${name.toLowerCase()}`}>
                  <InnerPanelHeader>
                    <OutlinedInputWithLabel label="Network name" value={name} />
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
                    <MUIBox
                      onMouseUp={createDropMouseUpHandler?.call(
                        null,
                        interfaces,
                      )}
                      sx={{
                        borderColor: TEXT,
                        borderStyle: 'dashed',
                        borderWidth: '4px',
                        display: 'flex',
                        flexDirection: 'column',
                        padding: '.6em',

                        '& > :not(:first-child)': {
                          marginTop: '.3em',
                        },
                      }}
                    >
                      {interfaces.length > 0 ? (
                        interfaces.map(
                          (networkInterface, networkInterfaceIndex) => {
                            const { networkInterfaceUUID } = networkInterface;

                            return (
                              <BriefNetworkInterface
                                key={`brief-network-interface-${networkInterfaceUUID}`}
                                networkInterface={networkInterface}
                                onClose={() => {
                                  interfaces.splice(networkInterfaceIndex, 1);

                                  networkInterfaceInputMap[
                                    networkInterfaceUUID
                                  ].isApplied = false;

                                  if (
                                    networkIndex > 1 &&
                                    interfaces.length === 0
                                  ) {
                                    networkInputs.splice(networkIndex, 1);
                                  }

                                  setNetworkInterfaceInputMap({
                                    ...networkInterfaceInputMap,
                                  });
                                }}
                              />
                            );
                          },
                        )
                      ) : (
                        <BodyText text="Drag interfaces here to add to this network." />
                      )}
                    </MUIBox>
                    <OutlinedInputWithLabel
                      label="IP address"
                      value={ipAddress}
                    />
                    <OutlinedInputWithLabel
                      label="Subnet mask"
                      value={subnetMask}
                    />
                  </MUIBox>
                </InnerPanel>
              ),
            )}
          </MUIBox>
        </MUIBox>
      )}
    </Panel>
  );
};

const Init: FC = () => (
  <MUIBox
    sx={{
      display: 'flex',
      flexDirection: 'column',
    }}
  >
    <NetworkInterfaceList />
  </MUIBox>
);

export default Init;
