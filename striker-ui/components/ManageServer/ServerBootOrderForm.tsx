import MuiArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import MuiArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import Grid from '@mui/material/Grid';
import styled from '@mui/material/styles/styled';
import { GridColDef } from '@mui/x-data-grid/models/colDef/gridColDef';
import capitalize from 'lodash/capitalize';
import { useMemo, useState } from 'react';

import FlexBox from '../FlexBox';
import handleFormSubmit from './handleFormSubmit';
import IconButton from '../IconButton';
import SelectDataGrid from './SelectDataGrid';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import { MonoText } from '../Text';
import useFormikUtils from '../../hooks/useFormikUtils';

const SelectDataGridWrapper = styled('div')({
  display: 'flex',
  flexDirection: 'column',
  width: '100%',
});

const ServerBootOrderForm: React.FC<ServerBootOrderFormProps> = (props) => {
  const { detail, tools } = props;

  const [selectedRowId, setSelectedRowId] = useState<number | undefined>();

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

  const chains = useMemo(
    () => ({
      order: `order`,
    }),
    [],
  );

  /**
   * Position of the selected row ID (or disk index) in the boot order array.
   */
  const selectedRowPosition = useMemo<number>(() => {
    if (selectedRowId === undefined) return -1;

    return formik.values.order.indexOf(selectedRowId);
  }, [formik.values.order, selectedRowId]);

  const disableUp = useMemo<boolean>(() => {
    const index = selectedRowPosition;

    return index < 1;
  }, [selectedRowPosition]);

  const disableDown = useMemo<boolean>(() => {
    const index = selectedRowPosition;

    const last = formik.values.order.length - 1;

    return index < 0 || index >= last;
  }, [formik.values.order.length, selectedRowPosition]);

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
          <FlexBox spacing=".6em">
            <IconButton
              disabled={disableUp}
              onClick={() => {
                const { order } = formik.values;

                const indexA = selectedRowPosition;

                if (disableUp) return;

                const indexB = indexA - 1;

                // Swap [..., b, a, ...] in boot array.

                const { [indexB]: b, [indexA]: a } = order;

                const clone = [...order];

                clone.splice(indexB, 2, a, b);

                formik.setFieldValue(chains.order, clone, true);
              }}
            >
              <MuiArrowUpwardIcon fontSize="small" />
            </IconButton>
            <IconButton
              disabled={disableDown}
              onClick={() => {
                const { order } = formik.values;

                const indexA = selectedRowPosition;

                if (disableDown) return;

                const indexB = indexA + 1;

                // Swap [..., a, b, ...] in boot array.

                const { [indexA]: a, [indexB]: b } = order;

                const clone = [...order];

                clone.splice(indexA, 2, b, a);

                formik.setFieldValue(chains.order, clone, true);
              }}
            >
              <MuiArrowDownwardIcon fontSize="small" />
            </IconButton>
          </FlexBox>
          <SelectDataGridWrapper>
            <SelectDataGrid<ServerBootOrderRow>
              columns={dataGridColumns}
              disableColumnMenu
              getRowId={(row) => row.index}
              hideFooter
              onRowSelectionModelChange={(model) => {
                const [rowId] = model;

                setSelectedRowId(Number(rowId));
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
