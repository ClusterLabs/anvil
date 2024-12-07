import { GridColDef, GridColumns } from '@mui/x-data-grid';
import { FC, useMemo } from 'react';

import ContainedButton from '../ContainedButton';
import DragDataGrid from '../HostNetInit/DragDataGrid';
import Spinner from '../Spinner';
import useFetch from '../../hooks/useFetch';

const ServerMigrationTable: FC<ServerMigrationTableProps> = (props) => {
  const { detail, servers } = props;

  const { altData: hostValues } = useFetch<
    APIHostOverviewList,
    APIHostOverview[]
  >('/host?types=node', {
    mod: (data) => {
      const values = Object.values(data);

      return values.filter((host) => host.anvil?.uuid === detail.anvil.uuid);
    },
  });

  const filteredServerValues = useMemo(
    () =>
      Object.values(servers).filter(
        (server) => server.anvil.uuid === detail.anvil.uuid,
      ),
    [detail.anvil.uuid, servers],
  );

  const dataGridRows = useMemo(
    () =>
      filteredServerValues.reduce<
        {
          columns: Record<string, { name: string }>;
          uuid: string;
        }[]
      >((previous, server) => {
        const { host, name, uuid } = server;

        // Don't include shut off hosts into the table
        if (!host) return previous;

        const { uuid: hostUuid } = host;

        const row = {
          columns: {
            [hostUuid]: { name },
          },
          uuid,
        };

        if (uuid === detail.uuid) {
          previous.unshift(row);
        } else {
          previous.push(row);
        }

        return previous;
      }, []),
    [detail.uuid, filteredServerValues],
  );

  const dataGridColumns = useMemo<GridColumns | undefined>(
    () =>
      hostValues &&
      hostValues.map<GridColDef>((host) => {
        const { hostUUID, shortHostName } = host;

        return {
          align: 'center',
          field: `hosts.${hostUUID}`,
          flex: 1.0 / hostValues.length,
          headerAlign: 'center',
          headerName: shortHostName,
          renderCell: (cell) => {
            const { row, value } = cell;

            if (row.uuid === detail.uuid && !value) {
              return <ContainedButton>Migrate</ContainedButton>;
            }

            return value;
          },
          sortable: false,
          valueGetter: (params) => {
            const { row } = params;

            const column = row.columns[hostUUID];

            if (!column) return '';

            return column.name;
          },
        };
      }),
    [detail.uuid, hostValues],
  );

  if (!dataGridColumns) {
    return <Spinner mt={0} />;
  }

  return (
    <DragDataGrid
      autoHeight
      columns={dataGridColumns}
      disableColumnMenu
      disableSelectionOnClick
      getRowId={(row) => row.uuid}
      hideFooter
      rows={dataGridRows}
    />
  );
};

export default ServerMigrationTable;
