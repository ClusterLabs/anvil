import { Grid, Switch } from '@mui/material';
import { capitalize } from 'lodash';
import { FC, useMemo, useRef } from 'react';

import { DialogWithHeader } from '../Dialog';
import Divider from '../Divider';
import FlexBox from '../FlexBox';
import handleAction from './handleAction';
import IconButton from '../IconButton';
import List from '../List';
import ServerAddInterfaceForm from './ServerAddInterfaceForm';
import { MonoText, SmallText } from '../Text';

const STATE_ACTION: Record<string, string> = {
  down: 'plug-in',
  up: 'unplug',
};

const STATE_LABEL: Record<string, string> = {
  down: 'unplugged',
  up: 'plugged-in',
};

const ServerInterfaceList: FC<ServerInterfaceListProps> = (props) => {
  const { detail, tools } = props;

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
            onAdd={() => {
              tools.add = {
                open: (value = false) => addDialogRef.current?.setOpen(value),
              };

              tools.add.open(true);
            }}
            renderListItem={(mac, iface) => {
              const {
                link: { state },
                model: { type },
                source: { bridge },
                target: { dev },
              } = iface;

              const active = state === 'up';

              return (
                <Grid alignItems="center" columnGap="1em" container>
                  <Grid
                    alignItems="center"
                    display="flex"
                    flexDirection="column"
                    item
                    minWidth="5em"
                  >
                    <SmallText noWrap>
                      {capitalize(STATE_LABEL[state])}
                    </SmallText>
                    <Switch
                      checked={active}
                      onChange={() => {
                        const { [state]: action } = STATE_ACTION;

                        handleAction(
                          tools,
                          `/server/${detail.uuid}/set-interface-state`,
                          `${capitalize(action)} ${dev} (${mac})?`,
                          {
                            body: { active: !active, mac },
                            messages: {
                              proceed: capitalize(action),
                              fail: (
                                <>Failed to register {action} interface job.</>
                              ),
                              success: (
                                <>
                                  Successfully registered {action} interface job
                                </>
                              ),
                            },
                          },
                        );
                      }}
                    />
                  </Grid>
                  <Grid item xs>
                    <FlexBox xs="column" sm="row" columnSpacing={0}>
                      <MonoText noWrap>
                        {dev} ({type})
                      </MonoText>
                      <Divider flexItem orientation="vertical" />
                      <MonoText noWrap>{mac}</MonoText>
                    </FlexBox>
                    <MonoText>{bridge}</MonoText>
                  </Grid>
                  <Grid item>
                    <IconButton
                      mapPreset="delete"
                      onClick={() => {
                        handleAction(
                          tools,
                          `/server/${detail.uuid}/delete-interface`,
                          `Delete ${dev} (${mac})?`,
                          {
                            body: { mac },
                            messages: {
                              proceed: 'Delete',
                              fail: (
                                <>Failed to register delete interface job.</>
                              ),
                              success: (
                                <>
                                  Successfully registered delete interface job
                                </>
                              ),
                            },
                          },
                        );
                      }}
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
        <ServerAddInterfaceForm {...props} />
      </DialogWithHeader>
    </>
  );
};

export default ServerInterfaceList;
