import { FC } from 'react';
import {
  Box as MUIBox,
  iconButtonClasses as muiIconButtonClasses,
} from '@mui/material';
import {
  DataGrid as MUIDataGrid,
  DataGridProps as MUIDataGridProps,
  gridClasses as muiGridClasses,
} from '@mui/x-data-grid';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { TEXT } from '../../lib/consts/DEFAULT_THEME';

import { Panel, PanelHeader } from '../../components/Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../../components/Spinner';
import { HeaderText } from '../../components/Text';

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

const NETWORK_INTERFACE_COLUMNS: MUIDataGridProps['columns'] = [
  {
    field: 'networkInterfaceMACAddress',
    flex: 1,
    headerName: 'MAC',
  },
  {
    field: 'networkInterfaceName',
    flex: 1,
    headerName: 'Name',
  },
  {
    field: 'networkInterfaceState',
    flex: 1,
    headerName: 'State',
  },
  {
    field: 'networkInterfaceSpeed',
    flex: 1,
    headerName: 'Speed',
    type: 'number',
  },
  {
    field: 'networkInterfaceOrder',
    flex: 1,
    headerName: 'Order',
    type: 'number',
  },
];

const NetworkInterfaceList: FC = () => {
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
        <MUIDataGrid
          autoHeight
          columns={NETWORK_INTERFACE_COLUMNS}
          disableColumnMenu
          disableSelectionOnClick
          getRowId={({ networkInterfaceUUID }) => networkInterfaceUUID}
          hideFooter
          rows={networkInterfaces}
          sx={{
            color: TEXT,

            [`& .${muiIconButtonClasses.root}`]: {
              color: 'inherit',
            },

            [`& .${muiGridClasses.cell}:focus`]: {
              outline: 'none',
            },
          }}
        />
      )}
    </Panel>
  );
};

const Init: FC = () => (
  <MUIBox>
    <NetworkInterfaceList />
  </MUIBox>
);

export default Init;
