import Grid from '@mui/material/Grid';
import MuiSwitch from '@mui/material/Switch';
import capitalize from 'lodash/capitalize';
import { useMemo, useRef, useState } from 'react';

import { DialogWithHeader } from '../Dialog';
import Divider from '../Divider';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import JobProgressList from '../JobProgressList';
import List from '../List';
import ServerAddInterfaceForm from './ServerAddInterfaceForm';
import { MonoText, SmallText } from '../Text';
import handleAction from './handleAction';

const STATE_ACTION: Record<string, string> = {
  down: 'plug-in',
  up: 'unplug',
};

const STATE_LABEL: Record<string, string> = {
  down: 'unplugged',
  up: 'plugged-in',
};

const ServerInterfaceList: React.FC<ServerInterfaceListProps> = (props) => {
  const { detail, tools } = props;

  const addDialogRef = useRef<DialogForwardedRefContent>(null);

  const [jobProgress, setJobProgress] = useState<number>(0);

  const [jobRegistered, setJobRegistered] = useState<boolean>(false);

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
                    <MuiSwitch
                      checked={active}
                      onChange={() => {
                        const { [state]: action } = STATE_ACTION;

                        setJobRegistered(false);

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
                            onSuccess: () => {
                              setJobRegistered(true);
                            },
                          },
                        );
                      }}
                    />
                  </Grid>
                  <Grid item xs>
                    <FlexBox xs="column" md="row" columnSpacing={0}>
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
        {jobRegistered && (
          <Grid item width="100%">
            <JobProgressList
              getLabel={(progress) =>
                progress === 100 ? 'Finished.' : 'Changing interface(s)...'
              }
              names={[`server::${detail.uuid}::set_interface_state`]}
              progress={{
                set: setJobProgress,
                value: jobProgress,
              }}
            />
          </Grid>
        )}
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
