import {
  Check as MuiCheckIcon,
  DragHandle as MuiDragHandleIcon,
} from '@mui/icons-material';
import { Box, BoxProps, Grid } from '@mui/material';
import { capitalize } from 'lodash';
import { FC, useMemo, useRef, useState } from 'react';
import { v4 as uuidv4 } from 'uuid';

import DragArea, { dragAreaClasses } from './DragArea';
import DragDataGrid, { dragDataGridClasses } from './DragDataGrid';
import guessHostNets from './guessHostNets';
import HostNetInputGroup from './HostNetInputGroup';
import IfaceDragHandle, { ifaceDragHandleClasses } from './IfaceDragHandle';
import IconButton from '../IconButton';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { FloatingIface } from './SimpleIface';
import Spinner from '../Spinner';
import { MonoText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFetch from '../../hooks/useFetch';

const HostNetInitInputGroup = <Values extends HostNetInitFormikExtension>(
  ...[props]: Parameters<FC<HostNetInitInputGroupProps<Values>>>
): ReturnType<FC<HostNetInitInputGroupProps<Values>>> => {
  const { formikUtils, host, onFetchSuccess } = props;

  const { formik, handleChange } = formikUtils;

  const firstResponse = useRef<boolean>(true);

  const [ifaceHeld, setIfaceHeld] = useState<string | undefined>();

  const [dragPosition, setDragPosition] = useState<DragPosition>({
    x: 0,
    y: 0,
  });

  const appliedIfaces = useMemo(
    () =>
      Object.values(formik.values.networkInit.networks).reduce<
        Record<string, boolean>
      >((applied, network) => {
        network.interfaces.forEach((uuid) => {
          if (uuid.length > 0) applied[uuid] = true;
        });

        return applied;
      }, {}),
    [formik.values.networkInit.networks],
  );

  const hostNets = useMemo(
    () => Object.entries(formik.values.networkInit.networks),
    [formik.values.networkInit.networks],
  );

  const chains = useMemo(() => {
    const base = 'networkInit';

    return {
      dns: `${base}.dns`,
      gateway: `${base}.gateway`,
      networkInit: base,
      networks: `${base}.networks`,
    };
  }, []);

  const { data: ifaces } = useFetch<APINetworkInterfaceOverviewList>(
    `/init/network-interface/${host.uuid}`,
    {
      onSuccess: (data) => {
        guessHostNets({
          appliedIfaces,
          chains,
          data,
          host,
          firstResponse,
          formikUtils,
        });

        onFetchSuccess?.call(null, data);
      },
      refreshInterval: 2000,
    },
  );

  const ifaceValues = useMemo(() => ifaces && Object.values(ifaces), [ifaces]);

  const dragAreaProps = useMemo<BoxProps | undefined>(() => {
    if (!ifaceHeld) return undefined;

    return {
      className: dragAreaClasses.dragging,
      onMouseLeave: () => setIfaceHeld(undefined),
      onMouseMove: (event) => {
        const {
          currentTarget,
          nativeEvent: { clientX, clientY },
        } = event;

        const { left, top } = currentTarget.getBoundingClientRect();

        setDragPosition({
          x: clientX - left,
          y: clientY - top,
        });
      },
      onMouseUp: () => setIfaceHeld(undefined),
    };
  }, [ifaceHeld]);

  if (!ifaces || !ifaceValues) {
    return <Spinner />;
  }

  return (
    <Grid columns={{ xs: 1, sm: 2, md: 3 }} container spacing="1em">
      <Grid item width="100%">
        <DragArea
          onMouseDown={(event) => {
            const { clientX, clientY, currentTarget } = event;

            const { left, top } = currentTarget.getBoundingClientRect();

            setDragPosition({
              x: clientX - left,
              y: clientY - top,
            });
          }}
          {...dragAreaProps}
        >
          {ifaceHeld && (
            <FloatingIface
              boxProps={{
                left: `calc(${dragPosition.x}px + .4em)`,
                top: `calc(${dragPosition.y}px - 1em)`,
              }}
              iface={ifaces[ifaceHeld]}
            />
          )}
          <DragDataGrid
            autoHeight
            columns={[
              {
                align: 'center',
                field: '',
                renderCell: (cell) => {
                  const { row } = cell;

                  let className;
                  let handleMouseDown:
                    | React.MouseEventHandler<HTMLDivElement>
                    | undefined = () => {
                    setIfaceHeld(row.uuid);
                  };
                  let icon = <MuiDragHandleIcon />;

                  if (appliedIfaces[row.uuid]) {
                    className = ifaceDragHandleClasses.applied;
                    handleMouseDown = undefined;
                    icon = <MuiCheckIcon />;
                  }

                  return (
                    <IfaceDragHandle
                      className={className}
                      onMouseDown={handleMouseDown}
                    >
                      {icon}
                    </IfaceDragHandle>
                  );
                },
                sortable: false,
                width: 1,
              },
              {
                field: 'name',
                flex: 1,
                headerName: 'Name',
              },
              {
                field: 'mac',
                flex: 1,
                headerName: 'MAC',
                renderCell: (cell) => {
                  const { value } = cell;

                  return <MonoText>{value}</MonoText>;
                },
              },
              {
                field: 'state',
                flex: 1,
                headerName: 'State',
                renderCell: (cell) => {
                  const { value } = cell;

                  return capitalize(value);
                },
              },
              {
                field: 'speed',
                flex: 1,
                headerName: 'Speed',
                renderCell: (cell) => {
                  const { value } = cell;

                  return `${value} Mbps`;
                },
              },
              {
                field: 'order',
                flex: 1,
                headerName: 'Order',
              },
            ]}
            componentsProps={{
              row: {
                onMouseDown: (
                  event: React.MouseEvent<HTMLDivElement>,
                ): void => {
                  const { target } = event;

                  const element = target as HTMLDivElement;

                  const uuid = element.parentElement?.dataset.id;

                  if (!uuid) return;

                  if (appliedIfaces[uuid]) return;

                  setIfaceHeld(uuid);
                },
              },
            }}
            disableColumnMenu
            disableSelectionOnClick
            getRowClassName={(cell) => {
              const { row } = cell;

              return ifaceHeld || appliedIfaces[row.uuid]
                ? ''
                : dragDataGridClasses.draggable;
            }}
            getRowId={(row) => row.uuid}
            hideFooter
            initialState={{
              sorting: { sortModel: [{ field: 'name', sort: 'asc' }] },
            }}
            rows={ifaceValues}
          />
          <Box
            sx={{
              display: 'grid',
              gridAutoColumns: {
                xs: '100%',
                sm: '50%',
                md: 'calc(100% / 3)',
              },
              gridAutoFlow: 'column',
              overflowX: 'scroll',
              scrollSnapType: 'x',

              '& > div': {
                scrollSnapAlign: 'start',
              },

              '& > :not(div:first-child)': {
                marginLeft: '1em',
              },
            }}
          >
            {hostNets.map((entry) => {
              const [key] = entry;

              return (
                <HostNetInputGroup<Values>
                  formikUtils={formikUtils}
                  host={host}
                  ifaceHeld={ifaceHeld}
                  ifaces={ifaces}
                  ifacesApplied={appliedIfaces}
                  ifacesValue={ifaceValues}
                  key={`hostnet-${key}`}
                  netId={key}
                />
              );
            })}
          </Box>
        </DragArea>
      </Grid>
      <Grid alignSelf="center" item xs={1} sm="auto">
        <IconButton
          mapPreset="add"
          onClick={() => {
            const key = uuidv4();

            formik.setFieldValue(
              `${chains.networks}.${key}`,
              {
                interfaces: ['', ''],
                ip: '',
                sequence: '',
                subnetMask: '',
                type: '',
              },
              true,
            );
          }}
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.gateway}
              label="Gateway"
              name={chains.gateway}
              onChange={handleChange}
              required
              value={formik.values.networkInit.gateway}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.dns}
              label="DNS"
              name={chains.dns}
              onChange={handleChange}
              value={formik.values.networkInit.dns}
            />
          }
        />
      </Grid>
    </Grid>
  );
};

export default HostNetInitInputGroup;
