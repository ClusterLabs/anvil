import { FC, useState } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  iconButtonClasses as muiIconButtonClasses,
} from '@mui/material';
import { DragHandle as MUIDragHandleIcon } from '@mui/icons-material';
import {
  DataGrid as MUIDataGrid,
  DataGridProps as MUIDataGridProps,
  gridClasses as muiGridClasses,
} from '@mui/x-data-grid';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { GREY, TEXT } from '../../lib/consts/DEFAULT_THEME';

import Decorator from '../../components/Decorator';
import { Panel, PanelHeader } from '../../components/Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../../components/Spinner';
import sumstring from '../../lib/sumstring';
import { BodyText, BodyTextProps, HeaderText } from '../../components/Text';

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

const createNetworkInterfaceTableColumns = (
  onMouseDownDragHandle: (
    row: NetworkInterfaceOverviewMetadata,
    ...eventArgs: Parameters<Exclude<MUIBoxProps['onMouseDown'], undefined>>
  ) => void,
): MUIDataGridProps['columns'] => [
  {
    align: 'center',
    field: '',
    renderCell: ({ row }) => (
      <MUIBox
        onMouseDown={(...eventArgs) => {
          onMouseDownDragHandle(row, ...eventArgs);
        }}
        sx={{
          alignItems: 'center',
          display: 'flex',
          flexDirection: 'row',

          '&:hover': { cursor: 'grab' },
        }}
      >
        <MUIDragHandleIcon />
      </MUIBox>
    ),
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
          colour={networkInterfaceState === 'up' ? 'ok' : 'warning'}
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
  const [networkInterfaceHeld, setNetworkInterfaceHeld] = useState<
    NetworkInterfaceOverviewMetadata | undefined
  >();

  const { data: networkInterfaces = MOCK_NICS, isLoading } = periodicFetch<
    NetworkInterfaceOverviewMetadata[]
  >(`${API_BASE_URL}/network-interface`, {
    refreshInterval: 2000,
  });

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
            })}
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
          <MUIBox
            onMouseUp={() => {
              setNetworkInterfaceHeld(undefined);
            }}
            sx={{
              borderColor: TEXT,
              borderStyle: 'dashed',
              borderWidth: '4px',
              height: '100px',
              width: '100px',
            }}
          />
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
