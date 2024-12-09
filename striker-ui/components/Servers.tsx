import { MoreVert as MoreVertIcon } from '@mui/icons-material';
import {
  Box,
  Checkbox,
  Divider,
  List,
  ListItem,
  styled,
  Typography,
} from '@mui/material';
import { useState, useContext, useRef, useMemo } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import {
  BLUE,
  DIVIDER,
  HOVER,
  LARGE_MOBILE_BREAKPOINT,
  RED,
  TEXT,
} from '../lib/consts/DEFAULT_THEME';
import serverState from '../lib/consts/SERVERS';

import api from '../lib/api';
import { AnvilContext } from './AnvilContext';
import ConfirmDialog from './ConfirmDialog';
import ContainedButton from './ContainedButton';
import Decorator, { Colours } from './Decorator';
import handleAPIError from '../lib/handleAPIError';
import hostsSanitizer from '../lib/sanitizers/hostsSanitizer';
import IconButton from './IconButton';
import Menu from './Menu';
import MenuItem from './MenuItem';
import { Panel, PanelHeader } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import ProvisionServerDialog from './ProvisionServerDialog';
import putFetch from '../lib/fetchers/putFetch';
import Spinner from './Spinner';
import { BodyText, HeaderText } from './Text';
import useConfirmDialogProps from '../hooks/useConfirmDialogProps';

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
  editButtonBox: `${PREFIX}-editButtonBox`,
  dropdown: `${PREFIX}-dropdown`,
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

  [`& .${classes.editButtonBox}`]: {
    paddingTop: '.3em',
  },

  [`& .${classes.dropdown}`]: {
    paddingTop: '.8em',
    paddingBottom: '.8em',
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
  const [isOpenProvisionServerDialog, setIsOpenProvisionServerDialog] =
    useState<boolean>(false);

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();

  const { uuid } = useContext(AnvilContext);

  const buttonLabels = useRef<ButtonLabels[]>([]);

  const { data: servers } = periodicFetch<APIServerOverviewList>(
    `${API_BASE_URL}/server?anvilUUIDs=${uuid}`,
  );

  const serverValues = useMemo(
    () => servers && Object.values(servers),
    [servers],
  );

  const setButtons = (filtered: APIServerOverview[]) => {
    buttonLabels.current = [];
    if (
      filtered.filter((item: APIServerOverview) => item.state === 'running')
        .length
    ) {
      buttonLabels.current.push('off');
    }

    if (
      filtered.filter((item: APIServerOverview) => item.state === 'shut off')
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
      selected.forEach((serverUuid) => {
        putFetch(
          `${API_BASE_URL}/command/${
            label === 'on' ? 'start-server' : 'stop-server'
          }/${serverUuid}`,
          {},
        );
      });
    }
  };

  const handleChange = (server_uuid: string): void => {
    if (!serverValues) return;

    const index = selected.indexOf(server_uuid);

    if (index === -1) {
      selected.push(server_uuid);
    } else {
      selected.splice(index, 1);
    }

    const filtered = serverValues.filter(
      (server: APIServerOverview) => selected.indexOf(server.uuid) !== -1,
    );
    setButtons(filtered);
    setSelected([...selected]);
  };

  const anvilIndex = anvil.findIndex((a) => a.anvil_uuid === uuid);

  const filteredHosts = hostsSanitizer(anvil[anvilIndex]?.hosts);

  const noneChecked = useMemo<boolean>(
    () => !selected.length,
    [selected.length],
  );

  return (
    <>
      <Panel>
        <StyledDiv>
          <PanelHeader
            className={classes.headerPadding}
            sx={{ marginBottom: 0 }}
          >
            <HeaderText text="Servers" />
            {showCheckbox && (
              <IconButton
                disabled={noneChecked}
                mapPreset="delete"
                onClick={() => {
                  setConfirmDialogProps({
                    actionProceedText: 'Delete',
                    content: `Are you sure you want to delete the selected server(s)? This action is not revertable.`,
                    onProceedAppend: () => {
                      api
                        .request({
                          data: { serverUuids: selected },
                          method: 'delete',
                          url: '/server',
                        })
                        .catch((error) => {
                          // TODO: find a place to display the error
                          handleAPIError(error);
                        });
                    },
                    proceedColour: 'red',
                    titleText: `Delete ${selected.length} server(s)?`,
                  });

                  confirmDialogRef.current.setOpen?.call(null, true);
                }}
                variant="redcontained"
              />
            )}
            <IconButton
              mapPreset="edit"
              onClick={() => setShowCheckbox(!showCheckbox)}
              state={String(showCheckbox)}
            />
            <IconButton
              mapPreset="add"
              onClick={() => setIsOpenProvisionServerDialog(true)}
            />
          </PanelHeader>
          {showCheckbox && (
            <>
              <Box className={classes.headerPadding} display="flex">
                <Box flexGrow={1} className={classes.dropdown}>
                  <ContainedButton
                    disabled={noneChecked}
                    onClick={handleClick}
                    startIcon={<MoreVertIcon />}
                  >
                    Power
                  </ContainedButton>
                  <Menu
                    muiMenuProps={{
                      anchorEl,
                      keepMounted: true,
                      onClose: () => setAnchorEl(null),
                    }}
                    open={Boolean(anchorEl)}
                  >
                    {buttonLabels.current.map((label: ButtonLabels) => (
                      <MenuItem onClick={() => handlePower(label)} key={label}>
                        <ServerActionButtonMenuItemLabel
                          className={classes[label]}
                          variant="subtitle1"
                        >
                          {label.replace(/^[a-z]/, (c) => c.toUpperCase())}
                        </ServerActionButtonMenuItemLabel>
                      </MenuItem>
                    ))}
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
                      if (!serverValues) return;

                      if (!allSelected) {
                        setButtons(serverValues);
                        setSelected(
                          serverValues.map(
                            (server: APIServerOverview) => server.uuid,
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
          {serverValues ? (
            <Box className={classes.root}>
              <List component="nav">
                {serverValues.map((server: APIServerOverview) => (
                  <>
                    <ListItem
                      button
                      className={classes.button}
                      key={server.uuid}
                      component={showCheckbox ? 'div' : 'a'}
                      href={`/server?uuid=${server.uuid}&server_name=${server.name}&server_state=${server.state}`}
                      onClick={() => handleChange(server.uuid)}
                    >
                      <Box display="flex" flexDirection="row" width="100%">
                        {showCheckbox && (
                          <Box className={classes.checkbox}>
                            <Checkbox
                              style={{ color: TEXT }}
                              color="secondary"
                              checked={
                                selected.find((s) => s === server.uuid) !==
                                undefined
                              }
                            />
                          </Box>
                        )}
                        <Box p={1}>
                          <Decorator colour={selectDecorator(server.state)} />
                        </Box>
                        <Box p={1} flexGrow={1}>
                          <BodyText text={server.name} />
                          <BodyText
                            text={
                              serverState.get(server.state) || 'Not Available'
                            }
                          />
                        </Box>
                        <Box display="flex" className={classes.hostsBox}>
                          {server.state !== 'shut off' &&
                            server.state !== 'crashed' &&
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
                                        server.host?.uuid === host.host_uuid
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
                ))}
              </List>
            </Box>
          ) : (
            <Spinner />
          )}
        </StyledDiv>
      </Panel>
      <ProvisionServerDialog
        dialogProps={{ open: isOpenProvisionServerDialog }}
        onClose={() => {
          setIsOpenProvisionServerDialog(false);
        }}
      />
      <ConfirmDialog
        closeOnProceed
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default Servers;
