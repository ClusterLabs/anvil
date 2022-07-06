import { FC } from 'react';
import {
  Box as MUIBox,
  iconButtonClasses as muiIconButtonClasses,
  tablePaginationClasses as muiTablePaginationClasses,
} from '@mui/material';
import { DataGrid as MUIDataGrid } from '@mui/x-data-grid';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { TEXT } from '../../lib/consts/DEFAULT_THEME';

import { Panel, PanelHeader } from '../../components/Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../../components/Spinner';
import { HeaderText } from '../../components/Text';

const NetworkInterfaceList: FC = () => {
  const { data: networkInterfaces = [], isLoading } = periodicFetch<
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
          columns={[
            { field: 'networkInterfaceMACAddress', flex: 1, headerName: 'MAC' },
            { field: 'networkInterfaceName', flex: 1, headerName: 'Name' },
            { field: 'networkInterfaceState', flex: 1, headerName: 'State' },
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
          ]}
          disableColumnMenu
          disableSelectionOnClick
          getRowId={({ networkInterfaceUUID }) => networkInterfaceUUID}
          hideFooter
          rows={networkInterfaces}
          sx={{
            color: TEXT,
            height: '50vh',

            [`& .${muiIconButtonClasses.root}`]: {
              color: TEXT,
            },

            [`& .${muiTablePaginationClasses.root}`]: {
              color: TEXT,
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
