import { useState, useContext, useRef } from 'react';
import {
  Box,
  Button,
  Checkbox,
  Divider,
  List,
  ListItem,
  Menu,
  MenuItem,
  styled,
  Typography,
} from '@mui/material';
import {
  Add as AddIcon,
  Check as CheckIcon,
  Edit as EditIcon,
  MoreVert as MoreVertIcon,
} from '@mui/icons-material';

import {
  BLACK,
  BLUE,
  DIVIDER,
  GREY,
  HOVER,
  LARGE_MOBILE_BREAKPOINT,
  RED,
  TEXT,
} from '../lib/consts/DEFAULT_THEME';
import serverState from '../lib/consts/SERVERS';

import { AnvilContext } from './AnvilContext';
import Decorator, { Colours } from './Decorator';
import IconButton from './IconButton';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { BodyText, HeaderText } from './Text';

import hostsSanitizer from '../lib/sanitizers/hostsSanitizer';
import periodicFetch from '../lib/fetchers/periodicFetch';
import putFetch from '../lib/fetchers/putFetch';

const PREFIX = 'Servers';

const classes = {
  root: `${PREFIX}-root`,
  divider: `${PREFIX}-divider`,
  verticalDivider: `${PREFIX}-verticalDivider`,
  button: `${PREFIX}-button`,
  headerPadding: `${PREFIX}-headerPadding`,
  hostsBox: `${PREFIX}-hostsBox`,
  hostBox: `${PREFIX}-hostBox`,
  checkbox: `${PREFIX}-checkbox`,
  serverActionButton: `${PREFIX}-serverActionButton`,
  editButtonBox: `${PREFIX}-editButtonBox`,
  dropdown: `${PREFIX}-dropdown`,
  power: `${PREFIX}-power`,
  on: `${PREFIX}-on`,
  off: `${PREFIX}-off`,
  all: `${PREFIX}-all`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.root}`]: {
    width: '100%',
    overflow: 'auto',
    height: '78vh',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
      overflow: 'hidden',
    },
  },

  [`& .${classes.divider}`]: {
    backgroundColor: DIVIDER,
  },

  [`& .${classes.verticalDivider}`]: {
    height: '75%',
    paddingTop: '1em',
  },

  [`& .${classes.button}`]: {
    '&:hover': {
      backgroundColor: HOVER,
    },
    paddingLeft: 0,
  },

  [`& .${classes.headerPadding}`]: {
    paddingLeft: '.3em',
  },

  [`& .${classes.hostsBox}`]: {
    padding: '1em',
    paddingRight: 0,
  },

  [`& .${classes.hostBox}`]: {
    paddingTop: 0,
  },

  [`& .${classes.checkbox}`]: {
    paddingTop: '.8em',
  },

  [`& .${classes.serverActionButton}`]: {
    backgroundColor: TEXT,
    color: BLACK,
    textTransform: 'none',
    '&:hover': {
      backgroundColor: GREY,
    },
  },

  [`& .${classes.editButtonBox}`]: {
    paddingTop: '.3em',
  },

  [`& .${classes.dropdown}`]: {
    paddingTop: '.8em',
    paddingBottom: '.8em',
  },

  [`& .${classes.power}`]: {
    color: BLACK,
  },

  [`& .${classes.all}`]: {
    paddingTop: '.5em',
    paddingLeft: '.3em',
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'running':
      return 'ok';
    case 'shut off':
      return 'off';
    case 'crashed':
      return 'error';
    default:
      return 'warning';
  }
};

const ServerActionButtonMenuItem = styled(MenuItem)({
  backgroundColor: GREY,
  paddingRight: '3em',
  '&:hover': {
    backgroundColor: GREY,
  },
});

const ServerActionButtonMenuItemLabel = styled(Typography)({
  [`&.${classes.on}`]: {
    color: BLUE,
  },

  [`&.${classes.off}`]: {
    color: RED,
  },
});

type ButtonLabels = 'on' | 'off';

const Servers = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [showCheckbox, setShowCheckbox] = useState<boolean>(false);
  const [allSelected, setAllSelected] = useState<boolean>(false);
  const [selected, setSelected] = useState<string[]>([]);

  const { uuid } = useContext(AnvilContext);

  const buttonLabels = useRef<ButtonLabels[]>([]);

  const { data, isLoading } = periodicFetch<AnvilServers>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_servers?anvil_uuid=${uuid}`,
  );

  const setButtons = (filtered: AnvilServer[]) => {
    buttonLabels.current = [];
    if (
      filtered.filter((item: AnvilServer) => item.server_state === 'running')
        .length
    ) {
      buttonLabels.current.push('off');
    }

    if (
      filtered.filter((item: AnvilServer) => item.server_state === 'shut off')
        .length
    ) {
      buttonLabels.current.push('on');
    }
  };

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>): void => {
    setAnchorEl(event.currentTarget);
  };

  const handlePower = (label: ButtonLabels) => {
    setAnchorEl(null);
    if (selected.length) {
      putFetch(`${process.env.NEXT_PUBLIC_API_URL}/set_power`, {
        server_uuid_list: selected,
        is_on: label === 'on',
      });
    }
  };

  const handleChange = (server_uuid: string): void => {
    const index = selected.indexOf(server_uuid);

    if (index === -1) selected.push(server_uuid);
    else selected.splice(index, 1);

    const filtered = data.servers.filter(
      (server: AnvilServer) => selected.indexOf(server.server_uuid) !== -1,
    );
    setButtons(filtered);
    setSelected([...selected]);
  };

  const anvilIndex = anvil.findIndex((a) => a.anvil_uuid === uuid);

  const filteredHosts = hostsSanitizer(anvil[anvilIndex]?.hosts);

  return (
    <Panel>
      <StyledDiv>
        <PanelHeader className={classes.headerPadding} sx={{ marginBottom: 0 }}>
          <HeaderText text="Servers" />
          <IconButton>
            <AddIcon />
          </IconButton>
          <IconButton onClick={() => setShowCheckbox(!showCheckbox)}>
            {showCheckbox ? <CheckIcon sx={{ color: BLUE }} /> : <EditIcon />}
          </IconButton>
        </PanelHeader>
        {showCheckbox && (
          <>
            <Box className={classes.headerPadding} display="flex">
              <Box flexGrow={1} className={classes.dropdown}>
                <Button
                  variant="contained"
                  startIcon={<MoreVertIcon />}
                  onClick={handleClick}
                  className={classes.serverActionButton}
                >
                  <Typography className={classes.power} variant="subtitle1">
                    Power
                  </Typography>
                </Button>
                <Menu
                  anchorEl={anchorEl}
                  keepMounted
                  open={Boolean(anchorEl)}
                  onClose={() => setAnchorEl(null)}
                >
                  {buttonLabels.current.map((label: ButtonLabels) => {
                    return (
                      <ServerActionButtonMenuItem
                        onClick={() => handlePower(label)}
                        key={label}
                      >
                        <ServerActionButtonMenuItemLabel
                          className={classes[label]}
                          variant="subtitle1"
                        >
                          {label.replace(/^[a-z]/, (c) => c.toUpperCase())}
                        </ServerActionButtonMenuItemLabel>
                      </ServerActionButtonMenuItem>
                    );
                  })}
                </Menu>
              </Box>
            </Box>
            <Box display="flex">
              <Box>
                <Checkbox
                  style={{ color: TEXT }}
                  color="secondary"
                  checked={allSelected}
                  onChange={() => {
                    if (!allSelected) {
                      setButtons(data.servers);
                      setSelected(
                        data.servers.map(
                          (server: AnvilServer) => server.server_uuid,
                        ),
                      );
                    } else {
                      setButtons([]);
                      setSelected([]);
                    }

                    setAllSelected(!allSelected);
                  }}
                />
              </Box>
              <Box className={classes.all}>
                <BodyText text="All" />
              </Box>
            </Box>
          </>
        )}
        {!isLoading ? (
          <Box className={classes.root}>
            <List component="nav">
              {data?.servers.map((server: AnvilServer) => {
                return (
                  <>
                    <ListItem
                      button
                      className={classes.button}
                      key={server.server_uuid}
                      component={showCheckbox ? 'div' : 'a'}
                      href={`/server?uuid=${server.server_uuid}&server_name=${server.server_name}`}
                      onClick={() => handleChange(server.server_uuid)}
                    >
                      <Box display="flex" flexDirection="row" width="100%">
                        {showCheckbox && (
                          <Box className={classes.checkbox}>
                            <Checkbox
                              style={{ color: TEXT }}
                              color="secondary"
                              checked={
                                selected.find(
                                  (s) => s === server.server_uuid,
                                ) !== undefined
                              }
                            />
                          </Box>
                        )}
                        <Box p={1}>
                          <Decorator
                            colour={selectDecorator(server.server_state)}
                          />
                        </Box>
                        <Box p={1} flexGrow={1}>
                          <BodyText text={server.server_name} />
                          <BodyText
                            text={
                              serverState.get(server.server_state) ||
                              'Not Available'
                            }
                          />
                        </Box>
                        <Box display="flex" className={classes.hostsBox}>
                          {server.server_state !== 'shut off' &&
                            server.server_state !== 'crashed' &&
                            filteredHosts.map(
                              (
                                host: AnvilStatusHost,
                                index: number,
                              ): JSX.Element => (
                                <>
                                  <Box
                                    p={1}
                                    key={host.host_uuid}
                                    className={classes.hostBox}
                                  >
                                    <BodyText
                                      text={host.host_name}
                                      selected={
                                        server.server_host_uuid ===
                                        host.host_uuid
                                      }
                                    />
                                  </Box>
                                  {index !== filteredHosts.length - 1 && (
                                    <Divider
                                      className={`${classes.divider} ${classes.verticalDivider}`}
                                      orientation="vertical"
                                    />
                                  )}
                                </>
                              ),
                            )}
                        </Box>
                      </Box>
                    </ListItem>
                    <Divider className={classes.divider} />
                  </>
                );
              })}
            </List>
          </Box>
        ) : (
          <Spinner />
        )}
      </StyledDiv>
    </Panel>
  );
};

export default Servers;
