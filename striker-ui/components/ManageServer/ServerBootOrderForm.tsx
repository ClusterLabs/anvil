import Grid from '@mui/material/Grid';
import styled from '@mui/material/styles/styled';
import { GridColDef } from '@mui/x-data-grid/models/colDef/gridColDef';
import capitalize from 'lodash/capitalize';
import { useMemo, useRef } from 'react';

import FlexBox from '../FlexBox';
import OrderControlBox, {
  OrderControlBoxForwardedRefContent,
} from './OrderControlBox';
import SelectDataGrid from './SelectDataGrid';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import { MonoText } from '../Text';
import handleFormSubmit from './handleFormSubmit';
import useFormikUtils from '../../hooks/useFormikUtils';

const SelectDataGridWrapper = styled('div')({
  display: 'flex',
  flexDirection: 'column',
  width: '100%',
});

const ServerBootOrderForm: React.FC<ServerBootOrderFormProps> = (props) => {
  const { detail, tools } = props;

  const controlRef = useRef<OrderControlBoxForwardedRefContent<number>>(null);

  const initialBootOrder = useMemo(() => {
    const [, ...disks] = detail.devices.diskOrderBy.boot;

    return disks;
  }, [detail.devices.diskOrderBy.boot]);

  const formikUtils = useFormikUtils<ServerBootOrderFormikValues>({
    initialValues: {
      order: initialBootOrder,
    },
    onSubmit: (values, helpers) => {
      handleFormSubmit(
        values,
        helpers,
        tools,
        () => `/server/${detail.uuid}/set-boot-order`,
        () => `Set boot order?`,
        {
          buildSummary: (v) => {
            const order = v.order.map<string>((diskIndex) => {
              const {
                [diskIndex]: {
                  target: { dev },
                },
              } = detail.devices.disks;

              return dev;
            });

            return { order };
          },
        },
      );
    },
  });

  const { disabledSubmit, formik } = formikUtils;

  const dataGridRows = useMemo(() => {
    const ls: number[] = formik.values.order;

    return ls.map<ServerBootOrderRow>((diskIndex) => {
      const {
        [diskIndex]: {
          device,
          source: {
            dev: { path: sdev = '' },
            file: { path: fpath = '' },
          },
          target: { dev },
        },
      } = detail.devices.disks;

      return {
        dev,
        index: diskIndex,
        name: device,
        source: sdev || fpath,
      };
    });
  }, [detail.devices.disks, formik.values.order]);

  const dataGridColumns = useMemo<GridColDef<ServerBootOrderRow, string>[]>(
    () => [
      {
        field: 'name',
        flex: 0,
        headerName: 'Name',
        renderCell: (cell) => {
          const { value: name = '' } = cell;

          let label: string = name;

          if (/cdrom/.test(name)) {
            label = 'optical';
          }

          label = capitalize(label);

          return label;
        },
        sortable: false,
      },
      {
        field: 'dev',
        flex: 0,
        headerName: 'Device',
        renderCell: (cell) => {
          const { value: dev } = cell;

          return <MonoText noWrap>{dev}</MonoText>;
        },
        sortable: false,
      },
      {
        field: 'source',
        flex: 1,
        headerName: 'Source',
        renderCell: (cell) => {
          const { value: source } = cell;

          return (
            <MonoText noWrap textOverflow="ellipsis">
              {source}
            </MonoText>
          );
        },
        sortable: false,
      },
    ],
    [],
  );

  return (
    <ServerFormGrid<ServerBootOrderFormikValues> formik={formik}>
      <Grid item width="100%">
        <FlexBox row spacing="1em">
          <OrderControlBox formikUtils={formikUtils} ref={controlRef} />
          <SelectDataGridWrapper>
            <SelectDataGrid<ServerBootOrderRow>
              columns={dataGridColumns}
              disableColumnMenu
              // Use disk index as row ID
              getRowId={(row) => row.index}
              hideFooter
              onRowSelectionModelChange={(model) => {
                const [rowId] = model;

                controlRef.current?.setSelectedId(Number(rowId));
              }}
              rows={dataGridRows}
            />
          </SelectDataGridWrapper>
        </FlexBox>
      </Grid>
      <Grid item width="100%">
        <ServerFormSubmit
          detail={detail}
          formDisabled={disabledSubmit}
          label="Save"
        />
      </Grid>
    </ServerFormGrid>
  );
};

export default ServerBootOrderForm;
