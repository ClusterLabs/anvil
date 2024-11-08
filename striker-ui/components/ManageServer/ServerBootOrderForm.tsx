import {
  ArrowDownward as ArrowDownwardIcon,
  ArrowUpward as ArrowUpwardIcon,
} from '@mui/icons-material';
import { Grid } from '@mui/material';
import { GridColumns } from '@mui/x-data-grid';
import { capitalize } from 'lodash';
import { FC, useMemo, useState } from 'react';

import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import SelectDataGrid from './SelectDataGrid';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import { MonoText } from '../Text';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerBootOrderForm: FC<ServerBootOrderFormProps> = (props) => {
  const { detail } = props;

  const [selectedRowId, setSelectedRowId] = useState<number | undefined>();

  const initialBootOrder = useMemo(() => {
    const [, ...disks] = detail.devices.diskOrderBy.boot;

    return disks;
  }, [detail.devices.diskOrderBy.boot]);

  const formikUtils = useFormikUtils<ServerBootOrderFormikValues>({
    initialValues: {
      order: initialBootOrder,
    },
    onSubmit: (values, { setSubmitting }) => {
      values.order.map<string>((diskIndex) => {
        const {
          [diskIndex]: {
            target: { dev },
          },
        } = detail.devices.disks;

        return dev;
      });

      setSubmitting(false);
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

  const dataGridRows = useMemo(
    () =>
      formik.values.order.map<{
        dev: string;
        index: number;
        name: string;
        source: string;
      }>((diskIndex) => {
        const {
          [diskIndex]: {
            device,
            source: { dev: sdev = '', file = '' },
            target: { dev },
          },
        } = detail.devices.disks;

        return {
          dev,
          index: diskIndex,
          name: device,
          source: sdev || file,
        };
      }),
    [detail.devices.disks, formik.values.order],
  );

  const dataGridColumns = useMemo<GridColumns>(
    () => [
      {
        field: 'name',
        flex: 0,
        headerName: 'Name',
        renderCell: (cell) => {
          const { value: name } = cell;

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
      <Grid item alignSelf="center">
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
            <ArrowUpwardIcon fontSize="small" />
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
            <ArrowDownwardIcon fontSize="small" />
          </IconButton>
        </FlexBox>
      </Grid>
      <Grid item flexGrow={1}>
        <SelectDataGrid
          autoHeight
          columns={dataGridColumns}
          disableColumnMenu
          getRowId={(row) => row.index}
          hideFooter
          onSelectionModelChange={(model) => {
            const [rowId] = model;

            setSelectedRowId(Number(rowId));
          }}
          rows={dataGridRows}
        />
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
