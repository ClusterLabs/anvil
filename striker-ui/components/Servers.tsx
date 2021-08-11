import { useState, useContext } from 'react';
import {
  List,
  ListItem,
  Divider,
  Box,
  IconButton,
  Button,
  Checkbox,
  Menu,
  MenuItem,
  Typography,
} from '@material-ui/core';
import EditIcon from '@material-ui/icons/Edit';
import MoreVertIcon from '@material-ui/icons/MoreVert';
import CheckIcon from '@material-ui/icons/Check';
import { makeStyles } from '@material-ui/core/styles';
import { Panel } from './Panels';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { HeaderText, BodyText } from './Text';
import {
  HOVER,
  DIVIDER,
  TEXT,
  BLUE,
  RED,
  GREY,
  BLACK,
  LARGE_MOBILE_BREAKPOINT,
} from '../lib/consts/DEFAULT_THEME';
import { AnvilContext } from './AnvilContext';
import serverState from '../lib/consts/SERVERS';
import Decorator, { Colours } from './Decorator';
import Spinner from './Spinner';
import hostsSanitizer from '../lib/sanitizers/hostsSanitizer';

import putFetch from '../lib/fetchers/putFetch';

const useStyles = makeStyles((theme) => ({
  root: {
    width: '100%',
    overflow: 'auto',
    height: '78vh',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
      overflow: 'hidden',
    },
  },
  divider: {
    background: DIVIDER,
  },
  verticalDivider: {
    height: '75%',
    paddingTop: '1em',
  },
  button: {
    '&:hover': {
      backgroundColor: HOVER,
    },
    paddingLeft: 0,
  },
  headerPadding: {
    paddingLeft: '.3em',
  },
  hostsBox: {
    padding: '1em',
    paddingRight: 0,
  },
  hostBox: {
    paddingTop: 0,
  },
  checkbox: {
    paddingTop: '.8em',
  },
  menuItem: {
    backgroundColor: TEXT,
    paddingRight: '3em',
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
  editButton: {
    borderRadius: 8,
    backgroundColor: GREY,
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
  editButtonBox: {
    paddingTop: '.3em',
  },
  dropdown: {
    paddingTop: '.8em',
    paddingBottom: '.8em',
  },
  power: {
    color: BLACK,
  },
  on: {
    color: BLUE,
  },
  off: {
    color: RED,
  },
  all: {
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

type ButtonLabels = 'on' | 'off';

const buttonLabels: ButtonLabels[] = ['on', 'off'];

const Servers = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [showCheckbox, setShowCheckbox] = useState<boolean>(false);
  const [allSelected, setAllSelected] = useState<boolean>(false);
  const [selected, setSelected] = useState<string[]>([]);
  const { uuid } = useContext(AnvilContext);
  const classes = useStyles();

  const { data, isLoading } = PeriodicFetch<AnvilServers>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_servers?anvil_uuid=${uuid}`,
  );

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

    setSelected([...selected]);
  };

  const anvilIndex = anvil.findIndex((a) => a.anvil_uuid === uuid);

  const filteredHosts = hostsSanitizer(anvil[anvilIndex]?.hosts);

  return (
    <Panel>
      <Box className={classes.headerPadding} display="flex">
        <Box flexGrow={1}>
          <HeaderText text="Servers" />
        </Box>
        <Box className={classes.editButtonBox}>
          <IconButton
            className={classes.editButton}
            style={{ color: BLACK }}
            onClick={() => setShowCheckbox(!showCheckbox)}
          >
            {showCheckbox ? <CheckIcon /> : <EditIcon />}
          </IconButton>
        </Box>
      </Box>
      {showCheckbox && (
        <>
          <Box className={classes.headerPadding} display="flex">
            <Box flexGrow={1} className={classes.dropdown}>
              <Button
                variant="contained"
                startIcon={<MoreVertIcon />}
                onClick={handleClick}
                style={{ textTransform: 'none' }}
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
                {buttonLabels.map((label: ButtonLabels) => {
                  return (
                    <MenuItem
                      onClick={() => handlePower(label)}
                      className={classes.menuItem}
                      key={label}
                    >
                      <Typography
                        className={classes[label]}
                        variant="subtitle1"
                      >
                        {label.replace(/^[a-z]/, (c) => c.toUpperCase())}
                      </Typography>
                    </MenuItem>
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
                  if (!allSelected)
                    setSelected(
                      data.servers.map(
                        (server: AnvilServer) => server.server_uuid,
                      ),
                    );
                  else setSelected([]);

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
            {data &&
              data.servers.map((server: AnvilServer) => {
                return (
                  <>
                    <ListItem
                      button
                      className={classes.button}
                      key={server.server_uuid}
                      component="a"
                      href={`/server?uuid=${server.server_uuid}&server_name=${server.server_name}`}
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
                              onChange={() => handleChange(server.server_uuid)}
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
    </Panel>
  );
};

export default Servers;
