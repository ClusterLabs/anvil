import MuiBox from '@mui/material/Box';
import MuiSwitch from '@mui/material/Switch';
import styled from '@mui/material/styles/styled';
import capitalize from 'lodash/capitalize';

import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';
import HOST_STATUS from '../../lib/consts/HOST_STATUS';

import api from '../../lib/api';
import { ProgressBar } from '../Bars';
import Decorator, { Colours } from '../Decorator';
import FlexBox from '../FlexBox';
import handleAPIError from '../../lib/handleAPIError';
import { InnerPanel, InnerPanelHeader } from '../Panels';
import { BodyText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';

type AnvilHostProps = {
  hosts: AnvilStatusHost[];
};

const PREFIX = 'AnvilHost';

const classes = {
  state: `${PREFIX}-state`,
  bar: `${PREFIX}-bar`,
  label: `${PREFIX}-label`,
  decoratorBox: `${PREFIX}-decoratorBox`,
};

const StyledBox = styled(MuiBox)(({ theme }) => ({
  overflow: 'auto',
  height: '28vh',
  paddingLeft: '.3em',
  paddingRight: '.3em',
  [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
    height: '100%',
    overflow: 'hidden',
  },

  [`& .${classes.state}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },

  [`& .${classes.bar}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },

  [`& .${classes.label}`]: {
    paddingTop: '.3em',
  },

  [`& .${classes.decoratorBox}`]: {
    alignSelf: 'stretch',
  },
}));

const selectStateMessage = (regex: RegExp, message: string): string => {
  const msg = regex.exec(message);

  if (msg) {
    return HOST_STATUS.get(msg[0]) || 'Error code not recognized';
  }
  return 'Error code not found';
};

const selectDecorator = (state: APIHostStatus): Colours => {
  switch (state) {
    case 'online':
      return 'ok';
    case 'powered off':
      return 'off';
    default:
      return 'warning';
  }
};

const AnvilHost: React.FC<AnvilHostProps> = (props) => {
  const { hosts } = props;

  const stateRegex = /^[a-zA-Z]/;
  const messageRegex = /^(message_[0-9]+)/;

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog();

  if (!hosts) {
    return <StyledBox />;
  }

  return (
    <>
      <StyledBox>
        {hosts.map((host): React.ReactNode => {
          // Temporary fix: avoid crash when encounter undefined host entry by returning a blank element.
          // TODO: figure out why there are undefined host entries.
          if (!host) {
            return undefined;
          }

          const online = host.state === 'online';
          const poweredOff = host.state === 'powered off';
          const notOnline = !online;
          const notPoweredOff = !poweredOff;

          return (
            <InnerPanel key={host.host_uuid}>
              <InnerPanelHeader>
                <MuiBox flexGrow={1}>
                  <BodyText text={host.host_name} />
                </MuiBox>
                <MuiBox className={classes.decoratorBox}>
                  <Decorator colour={selectDecorator(host.state)} />
                </MuiBox>
                <MuiBox>
                  <BodyText
                    text={
                      host?.state?.replace(stateRegex, (c) =>
                        c.toUpperCase(),
                      ) || 'Not Available'
                    }
                  />
                </MuiBox>
              </InnerPanelHeader>
              <MuiBox display="flex" className={classes.state}>
                <MuiBox className={classes.label}>
                  <BodyText text="Power: " />
                </MuiBox>
                <MuiBox flexGrow={1}>
                  <MuiSwitch
                    checked={notPoweredOff}
                    onChange={() => {
                      const action = notPoweredOff ? 'stop' : 'start';
                      const command = `${action}-subnode`;

                      const capped = capitalize(action);

                      let content: React.ReactNode;

                      if (action === 'start') {
                        content = (
                          <BodyText>
                            The subnode will be powered on with IPMI commands.
                          </BodyText>
                        );
                      } else {
                        content = (
                          <FlexBox>
                            <BodyText>
                              The subnode will be powered off.
                            </BodyText>
                            <BodyText>
                              {host.server_count ? (
                                <>
                                  All {host.server_count} servers on this
                                  subnode will be migrated to the peer subnode
                                  if possible. Otherwise, the servers will be
                                  shut down.
                                </>
                              ) : (
                                <>No servers are on this subnode.</>
                              )}
                            </BodyText>
                          </FlexBox>
                        );
                      }

                      setConfirmDialogProps({
                        actionProceedText: capped,
                        content,
                        onProceedAppend: () => {
                          setConfirmDialogLoading(true);

                          api
                            .put(`/command/${command}/${host.host_uuid}`)
                            .then(() => {
                              finishConfirm('Success', {
                                children: (
                                  <>Successfully registered power job.</>
                                ),
                              });
                            })
                            .catch((error) => {
                              const emsg = handleAPIError(error);

                              emsg.children = (
                                <>
                                  Failed to register power job. {emsg.children}
                                </>
                              );

                              finishConfirm('Error', emsg);
                            });
                        },
                        titleText: `${capped} ${host.host_name}?`,
                      });

                      setConfirmDialogOpen(true);
                    }}
                  />
                </MuiBox>
                <MuiBox className={classes.label}>
                  <BodyText text="Member: " />
                </MuiBox>
                <MuiBox>
                  <MuiSwitch
                    checked={online}
                    disabled={poweredOff}
                    onChange={() => {
                      const action = online ? 'leave' : 'join';
                      const command = `${action}-an`;

                      const capped = capitalize(action);

                      let content: React.ReactNode;

                      if (action === 'leave') {
                        content = (
                          <FlexBox>
                            <BodyText>
                              The subnode will be withdrawn from its cluster and
                              servers will be migrated as necessary.
                            </BodyText>
                            <BodyText>
                              The operation is reversible. You can tell it to
                              join the cluster again later.
                            </BodyText>
                          </FlexBox>
                        );
                      } else {
                        content = (
                          <FlexBox>
                            <BodyText>
                              The subnode will join the cluster it belongs to.
                            </BodyText>
                            <BodyText>
                              The operation is reversible. You can tell it to
                              withdraw from the cluster again later.
                            </BodyText>
                          </FlexBox>
                        );
                      }

                      setConfirmDialogProps({
                        actionProceedText: capped,
                        content,
                        onProceedAppend: () => {
                          setConfirmDialogLoading(true);

                          api
                            .put(`/command/${command}/${host.host_uuid}`)
                            .then(() => {
                              finishConfirm('Success', {
                                children: (
                                  <>
                                    Successfully registered cluster membership
                                    job.
                                  </>
                                ),
                              });
                            })
                            .catch((error) => {
                              const emsg = handleAPIError(error);

                              emsg.children = (
                                <>
                                  Failed to register cluster memebership job.{' '}
                                  {emsg.children}
                                </>
                              );

                              finishConfirm('Error', emsg);
                            });
                        },
                        titleText: `${capped} cluster on ${host.host_name}?`,
                      });

                      setConfirmDialogOpen(true);
                    }}
                  />
                </MuiBox>
              </MuiBox>
              {notOnline && notPoweredOff && (
                <>
                  <MuiBox display="flex" width="100%" className={classes.state}>
                    <MuiBox>
                      <BodyText
                        text={selectStateMessage(
                          messageRegex,
                          host.state_message,
                        )}
                      />
                    </MuiBox>
                  </MuiBox>
                  <MuiBox display="flex" width="100%" className={classes.bar}>
                    <MuiBox flexGrow={1}>
                      <ProgressBar progressPercentage={host.state_percent} />
                    </MuiBox>
                  </MuiBox>
                </>
              )}
            </InnerPanel>
          );
        })}
      </StyledBox>
      {confirmDialog}
    </>
  );
};

export default AnvilHost;
