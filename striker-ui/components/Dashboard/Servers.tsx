import {
  MoreVert as MoreVertIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { Box, boxClasses, Grid } from '@mui/material';
import { debounce } from 'lodash';
import { useMemo, useState } from 'react';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import ContainedButton from '../ContainedButton';
import Divider from '../Divider';
import IconButton from '../IconButton';
import Menu from '../Menu';
import MenuItem from '../MenuItem';
import MessageBox from '../MessageBox';
import OutlinedInput from '../OutlinedInput';
import { Panel, PanelHeader } from '../Panels';
import ProvisionServerDialog from '../ProvisionServerDialog';
import ServerLists from './ServerLists';
import ServerPanels from './ServerPanels';
import Spinner from '../Spinner';
import SyncIndicator from '../SyncIndicator';
import { BodyText, HeaderText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFetch from '../../hooks/useFetch';

const group = (
  list?: APIServerOverviewList,
  keywords?: string,
): ServerGroups => {
  const result: ServerGroups = {
    match: [],
    none: [],
  };

  if (!list) {
    return result;
  }

  const uuids = Object.keys(list);

  if (!keywords) {
    result.none = uuids;

    return result;
  }

  uuids.reduce<ServerGroups>((previous, uuid) => {
    const server = list[uuid];

    const pattern = new RegExp(keywords, 'i');
    const string = JSON.stringify(server);

    if (pattern.test(string)) {
      previous.match.push(uuid);

      return previous;
    }

    previous.none.push(uuid);

    return previous;
  }, result);

  return result;
};

const Servers: React.FC = () => {
  const [viewAnchor, setViewAnchor] = useState<HTMLElement | null>(null);
  const [groups, setGroups] = useState<ServerGroups | undefined>();
  const [provision, setProvision] = useState<boolean>(false);
  const [searchString, setSearchString] = useState<string>('');

  const {
    data: servers,
    loading,
    error: fetchError,
    validating,
  } = useFetch<APIServerOverviewList>('/server', {
    refreshInterval: 4000,
    onSuccess: (data) => {
      setGroups(group(data, searchString));
    },
  });

  const changeGroups = useMemo(
    () =>
      debounce((...args: Parameters<typeof group>) => {
        const [, value = ''] = args;

        setSearchString(value);
        setGroups(group(...args));
      }, 500),
    [],
  );

  const noMatchMsg = useMemo(() => {
    if (!searchString || groups?.match.length) {
      return undefined;
    }

    return (
      <>
        <Grid item width="100%">
          <BodyText noWrap>No match</BodyText>
        </Grid>
        <Grid item width="100%">
          <Divider orientation="horizontal" />
        </Grid>
      </>
    );
  }, [groups?.match.length, searchString]);

  if (loading) {
    return (
      <Panel>
        <Spinner mt={0} />
      </Panel>
    );
  }

  if (!servers || !groups) {
    return (
      <Panel>
        <MessageBox type="warning">
          Couldn&apos;t get the list of servers. {fetchError?.message}
        </MessageBox>
      </Panel>
    );
  }

  let view: React.ReactNode;

  const viewKey = 'preferences.servers.view';
  const viewType = localStorage.getItem(viewKey);

  if (viewType === 'list') {
    view = <ServerLists groups={groups} servers={servers} />;
  } else {
    view = <ServerPanels groups={groups} servers={servers} />;
  }

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Servers</HeaderText>
          <SyncIndicator syncing={validating} />
          <Box
            sx={{
              [`&.${boxClasses.root}`]: {
                marginRight: '.5em',
              },
            }}
          >
            <ContainedButton
              onClick={(event) => {
                setViewAnchor(event.currentTarget);
              }}
              startIcon={<MoreVertIcon />}
              sx={{
                lineHeight: 2,
              }}
            >
              View
            </ContainedButton>
            <Menu
              muiMenuProps={{
                anchorEl: viewAnchor,
                keepMounted: true,
                onClose: () => setViewAnchor(null),
              }}
              open={Boolean(viewAnchor)}
            >
              <MenuItem
                onClick={() => {
                  localStorage.setItem(viewKey, 'previews');
                  setViewAnchor(null);
                }}
              >
                <BodyText inheritColour>Previews</BodyText>
              </MenuItem>
              <MenuItem
                onClick={() => {
                  localStorage.setItem(viewKey, 'list');
                  setViewAnchor(null);
                }}
              >
                <BodyText inheritColour>List</BodyText>
              </MenuItem>
            </Menu>
          </Box>
          <IconButton
            mapPreset="add"
            onClick={() => {
              setProvision(true);
            }}
          />
          <UncontrolledInput
            input={
              <OutlinedInput
                onChange={(event) => {
                  const { value } = event.target;

                  changeGroups(servers, value);
                }}
                startAdornment={
                  <SearchIcon
                    sx={{
                      color: DIVIDER,
                      marginRight: '.4em',
                    }}
                  />
                }
                sx={{ width: '20em' }}
              />
            }
          />
        </PanelHeader>
        <Grid container spacing="1em">
          {noMatchMsg}
          <Grid item width="100%">
            {view}
          </Grid>
        </Grid>
      </Panel>
      <ProvisionServerDialog
        dialogProps={{ open: provision }}
        onClose={() => {
          setProvision(false);
        }}
      />
    </>
  );
};

export default Servers;
