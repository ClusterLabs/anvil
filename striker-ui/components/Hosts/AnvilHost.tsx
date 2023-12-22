import { Box, styled, Switch } from '@mui/material';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';
import HOST_STATUS from '../../lib/consts/HOST_STATUS';

import { ProgressBar } from '../Bars';
import Decorator, { Colours } from '../Decorator';
import { InnerPanel, InnerPanelHeader } from '../Panels';
import putFetch from '../../lib/fetchers/putFetch';
import { BodyText } from '../Text';

const PREFIX = 'AnvilHost';

const classes = {
  state: `${PREFIX}-state`,
  bar: `${PREFIX}-bar`,
  label: `${PREFIX}-label`,
  decoratorBox: `${PREFIX}-decoratorBox`,
};

const StyledBox = styled(Box)(({ theme }) => ({
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

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'online':
      return 'ok';
    case 'offline':
      return 'off';
    default:
      return 'warning';
  }
};

const AnvilHost = ({
  hosts,
}: {
  hosts: Array<AnvilStatusHost>;
}): JSX.Element => {
  const stateRegex = /^[a-zA-Z]/;
  const messageRegex = /^(message_[0-9]+)/;

  return (
    <StyledBox>
      {hosts &&
        hosts.map(
          (host): JSX.Element =>
            // Temporary fix: avoid crash when encounter undefined host entry by returning a blank element.
            // TODO: figure out why there are undefined host entries.
            host ? (
              <InnerPanel key={host.host_uuid}>
                <InnerPanelHeader>
                  <Box flexGrow={1}>
                    <BodyText text={host.host_name} />
                  </Box>
                  <Box className={classes.decoratorBox}>
                    <Decorator colour={selectDecorator(host.state)} />
                  </Box>
                  <Box>
                    <BodyText
                      text={
                        host?.state?.replace(stateRegex, (c) =>
                          c.toUpperCase(),
                        ) || 'Not Available'
                      }
                    />
                  </Box>
                </InnerPanelHeader>
                <Box display="flex" className={classes.state}>
                  <Box className={classes.label}>
                    <BodyText text="Power: " />
                  </Box>
                  <Box flexGrow={1}>
                    <Switch
                      checked={host.state === 'online'}
                      onChange={() =>
                        putFetch(
                          `${API_BASE_URL}/command/${
                            host.state === 'online'
                              ? 'stop-subnode'
                              : 'start-subnode'
                          }/${host.host_uuid}`,
                          {},
                        )
                      }
                    />
                  </Box>
                  <Box className={classes.label}>
                    <BodyText text="Member: " />
                  </Box>
                  <Box>
                    <Switch
                      checked={host.state === 'online'}
                      disabled={!(host.state === 'online')}
                      onChange={() =>
                        putFetch(
                          `${API_BASE_URL}/command/${
                            host.state === 'online' ? 'leave-an' : 'join-an'
                          }/${host.host_uuid}`,
                          {},
                        )
                      }
                    />
                  </Box>
                </Box>
                {host.state !== 'online' && host.state !== 'offline' && (
                  <>
                    <Box display="flex" width="100%" className={classes.state}>
                      <Box>
                        <BodyText
                          text={selectStateMessage(
                            messageRegex,
                            host.state_message,
                          )}
                        />
                      </Box>
                    </Box>
                    <Box display="flex" width="100%" className={classes.bar}>
                      <Box flexGrow={1}>
                        <ProgressBar progressPercentage={host.state_percent} />
                      </Box>
                    </Box>
                  </>
                )}
              </InnerPanel>
            ) : (
              <></>
            ),
        )}
    </StyledBox>
  );
};

export default AnvilHost;
