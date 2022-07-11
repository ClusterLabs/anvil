import { FC, useEffect, useState } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  iconButtonClasses as muiIconButtonClasses,
} from '@mui/material';
import {
  Check as MUICheckIcon,
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

const BriefNetworkInterface: FC<{
  networkInterface: NetworkInterfaceOverviewMetadata;
}> = ({
  networkInterface: { networkInterfaceName, networkInterfaceState },
}) => (
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
    <BodyText text={networkInterfaceName} />
  </MUIBox>
);

const createNetworkInterfaceTableColumns = (
  onMouseDownDragHandler: (
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
      let handleOnMouseDown: MUIBoxProps['onMouseDown'] = (...eventArgs) => {
        onMouseDownDragHandler(row, ...eventArgs);
      };
      let icon = <MUIDragHandleIcon />;

      if (isApplied) {
        cursor = 'auto';
        handleOnMouseDown = undefined;
        icon = <MUICheckIcon sx={{ color: BLUE }} />;
      }

      return (
        <MUIBox
          onMouseDown={handleOnMouseDown}
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
    <Panel>
      <PanelHeader>
        <HeaderText text="Network Interfaces" />
      </PanelHeader>
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
          <BodyText
            text={`Network interface held: ${
              networkInterfaceHeld?.networkInterfaceName || 'none'
            }`}
          />

          {networkInputs.map(({ interfaces, ipAddress, name, subnetMask }) => (
            <InnerPanel key={`network-input-${name.toLowerCase()}`}>
              <InnerPanelHeader>
                <BodyText text={name} />
              </InnerPanelHeader>
              <MUIBox
                sx={{
                  display: 'flex',
                  flexDirection: { xs: 'column', md: 'row' },
                  margin: '.6em',

                  '& > *': {
                    flexBasis: '50%',
                  },
                }}
              >
                <MUIBox
                  onMouseUp={() => {
                    if (networkInterfaceHeld) {
                      interfaces.push(networkInterfaceHeld);

                      networkInterfaceInputMap[
                        networkInterfaceHeld.networkInterfaceUUID
                      ].isApplied = true;
                    }

                    setNetworkInterfaceHeld(undefined);
                  }}
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
                    interfaces.map((networkInterface) => (
                      <BriefNetworkInterface
                        key={`brief-network-interface-${networkInterface.networkInterfaceUUID}`}
                        networkInterface={networkInterface}
                      />
                    ))
                  ) : (
                    <BodyText text="Drag interfaces here to add." />
                  )}
                </MUIBox>
                <MUIBox
                  sx={{
                    display: 'flex',
                    flexDirection: 'column',
                  }}
                >
                  <OutlinedInputWithLabel
                    label="IP address"
                    value={ipAddress}
                  />
                  <OutlinedInputWithLabel
                    label="Subnet mask"
                    value={subnetMask}
                  />
                </MUIBox>
              </MUIBox>
            </InnerPanel>
          ))}
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
