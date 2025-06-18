import MuiCheckIcon from '@mui/icons-material/Check';
import MuiDragHandleIcon from '@mui/icons-material/DragHandle';
import MuiBox, { BoxProps as MuiBoxProps } from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import { GridColDef } from '@mui/x-data-grid/models/colDef/gridColDef';
import capitalize from 'lodash/capitalize';
import { useMemo, useState } from 'react';
import { v4 as uuidv4 } from 'uuid';

import Decorator, { Colours } from '../Decorator';
import DragArea, { dragAreaClasses } from './DragArea';
import DragDataGrid, { dragDataGridClasses } from './DragDataGrid';
import FlexBox from '../FlexBox';
import guessHostNets from './guessHostNets';
import HostNetBox from './HostNetBox';
import HostNetInputGroup from './HostNetInputGroup';
import IfaceDragHandle, { ifaceDragHandleClasses } from './IfaceDragHandle';
import IconButton from '../IconButton';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { FloatingIface } from './SimpleIface';
import Spinner from '../Spinner';
import SyncIndicator from '../SyncIndicator';
import { MonoText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFetch from '../../hooks/useFetch';

const HostNetInitInputGroup = <Values extends HostNetInitFormikExtension>(
  ...[props]: Parameters<React.FC<HostNetInitInputGroupProps<Values>>>
): ReturnType<React.FC<HostNetInitInputGroupProps<Values>>> => {
  const { formikUtils, host, onFetchSuccess } = props;

  const { formik, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = 'networkInit';

    return {
      dns: `${base}.dns`,
      gateway: `${base}.gateway`,
      networkInit: base,
      networks: `${base}.networks`,
      ntp: `${base}.ntp`,
    };
  }, []);

  const [ifaceHeld, setIfaceHeld] = useState<string | undefined>();

  const [dragPosition, setDragPosition] = useState<DragPosition>({
    x: 0,
    y: 0,
  });

  const [lostConnection, setLostConnection] = useState<boolean>(false);

  const appliedIfaces = useMemo(
    () =>
      Object.values<HostNetFormikValues>(
        formik.values.networkInit.networks,
      ).reduce<Record<string, boolean>>((applied, network) => {
        network.interfaces.forEach((uuid) => {
          if (!uuid) return;

          applied[uuid] = true;
        });

        return applied;
      }, {}),
    [formik.values.networkInit.networks],
  );

  const { data: ifaces, validating: validatingIfaces } =
    useFetch<APINetworkInterfaceOverviewList>(
      `/init/network-interface/${host.uuid}`,
      {
        onError: () => {
          setLostConnection(true);
        },
        onSuccess: (data) => {
          setLostConnection(false);

          guessHostNets({
            appliedIfaces,
            chains,
            data,
            host,
            formikUtils,
          });

          onFetchSuccess?.call(null, data);
        },
        refreshInterval: 2000,
      },
    );

  const hostNets = useMemo(
    () =>
      Object.entries<HostNetFormikValues>(formik.values.networkInit.networks),
    [formik.values.networkInit.networks],
  );

  const ifaceValues = useMemo(() => ifaces && Object.values(ifaces), [ifaces]);

  const dragAreaProps = useMemo<MuiBoxProps | undefined>(() => {
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

  const disableAddNet = useMemo(() => {
    if (!ifaceValues?.length) return true;

    const allocated = Object.keys(appliedIfaces).length;
    const available = ifaceValues.length - allocated;

    const slots = hostNets.filter(
      ([, hostNet]) => !hostNet.interfaces[0],
    ).length;

    return available <= slots;
  }, [appliedIfaces, hostNets, ifaceValues?.length]);

  const dataColumns = useMemo<GridColDef<APINetworkInterfaceOverview>[]>(
    (): GridColDef<APINetworkInterfaceOverview>[] => [
      {
        align: 'center',
        display: 'flex',
        field: '',
        renderCell: (cell) => {
          const { uuid } = cell.row;

          let className;
          let handleMouseDown:
            | React.MouseEventHandler<HTMLDivElement>
            | undefined = () => {
            setIfaceHeld(uuid);
          };
          let icon = <MuiDragHandleIcon />;

          if (appliedIfaces[uuid]) {
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
        renderHeader: () => <SyncIndicator syncing={validatingIfaces} />,
        sortable: false,
        width: 1,
      },
      {
        display: 'flex',
        field: 'name',
        flex: 1,
        headerName: 'Name',
        renderCell: (cell) => {
          const { name, state } = cell.row;

          let colour: Colours;

          if (lostConnection || state === 'down') {
            colour = 'warning';
          } else if (state === 'up') {
            colour = 'ok';
          } else {
            colour = 'error';
          }

          return (
            <FlexBox row>
              <Decorator
                colour={colour}
                sx={{ alignSelf: 'stretch', height: 'auto' }}
              />
              <MonoText>{name}</MonoText>
            </FlexBox>
          );
        },
      },
      {
        field: 'mac',
        flex: 1,
        headerName: 'MAC',
        renderCell: (cell) => {
          const { mac } = cell.row;

          return <MonoText>{mac}</MonoText>;
        },
      },
      {
        field: 'state',
        flex: 1,
        headerName: 'State',
        renderCell: (cell) => {
          const { state } = cell.row;

          return lostConnection ? 'Lost' : capitalize(state);
        },
      },
      {
        field: 'speed',
        flex: 1,
        headerName: 'Speed',
        renderCell: (cell) => {
          const { speed } = cell.row;

          return `${speed} Mbps`;
        },
      },
      {
        field: 'order',
        flex: 1,
        headerName: 'Order',
      },
    ],
    [appliedIfaces, lostConnection, validatingIfaces],
  );

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
          <DragDataGrid<APINetworkInterfaceOverview>
            autoHeight
            columns={dataColumns}
            disableColumnMenu
            disableRowSelectionOnClick
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
            slotProps={{
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
          />
          <HostNetBox>
            {hostNets.map((entry) => {
              const [key] = entry;

              return (
                <MuiBox key={`hostnet-${key}`}>
                  <HostNetInputGroup<Values>
                    appliedIfaces={appliedIfaces}
                    formikUtils={formikUtils}
                    host={host}
                    ifaceHeld={ifaceHeld}
                    ifaces={ifaces}
                    ifaceValues={ifaceValues}
                    netId={key}
                  />
                </MuiBox>
              );
            })}
          </HostNetBox>
        </DragArea>
      </Grid>
      <Grid alignSelf="center" item xs={1} sm="auto">
        <IconButton
          disabled={disableAddNet}
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
      <Grid item xs={1} sm md="auto">
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
      <Grid item xs={1} sm md="auto">
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
      <Grid item xs={1} sm md="auto">
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.ntp}
              label="NTP"
              name={chains.ntp}
              onChange={handleChange}
              value={formik.values.networkInit.ntp}
            />
          }
        />
      </Grid>
    </Grid>
  );
};

export default HostNetInitInputGroup;
