import { Grid, Switch } from '@mui/material';
import { capitalize } from 'lodash';
import { FC, useMemo, useRef } from 'react';

import { DialogWithHeader } from '../Dialog';
import Divider from '../Divider';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import List from '../List';
import ServerAddInterfaceForm from './ServerAddInterfaceForm';
import { MonoText, SmallText } from '../Text';

const ServerInterfaceList: FC<ServerInterfaceListProps> = (props) => {
  const { detail } = props;

  const addDialogRef = useRef<DialogForwardedRefContent>(null);

  const ifaces = useMemo(
    () =>
      detail.devices.interfaces.reduce<
        Record<string, APIServerDetailInterface>
      >((previous, iface) => {
        previous[iface.mac.address] = iface;

        return previous;
      }, {}),
    [detail.devices.interfaces],
  );

  return (
    <>
      <Grid container>
        <Grid item width="100%">
          <List
            allowAddItem
            header
            listEmpty="No server network interface(s) found."
            listItems={ifaces}
            onAdd={() => addDialogRef.current?.setOpen(true)}
            renderListItem={(mac, iface) => {
              const {
                link: { state },
                model: { type },
                source: { bridge },
                target: { dev },
              } = iface;

              const active = state === 'up';

              return (
                <Grid container columnGap="1em">
                  <Grid item alignSelf="center">
                    <SmallText monospaced textAlign="center">
                      {capitalize(state)}
                    </SmallText>
                    <Switch checked={active} />
                  </Grid>
                  <Grid item flexGrow={1}>
                    <FlexBox xs="column" sm="row" columnSpacing={0}>
                      <MonoText>
                        {dev} ({type})
                      </MonoText>
                      <Divider flexItem orientation="vertical" />
                      <MonoText noWrap>{mac}</MonoText>
                    </FlexBox>
                    <MonoText>{bridge}</MonoText>
                  </Grid>
                  <Grid item alignSelf="center">
                    <IconButton
                      mapPreset="delete"
                      size="small"
                      variant="redcontained"
                    />
                  </Grid>
                </Grid>
              );
            }}
          />
        </Grid>
      </Grid>
      <DialogWithHeader
        header="Add interface"
        ref={addDialogRef}
        showClose
        wide
      >
        <ServerAddInterfaceForm detail={detail} />
      </DialogWithHeader>
    </>
  );
};

export default ServerInterfaceList;
