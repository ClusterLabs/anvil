import { Search as SearchIcon } from '@mui/icons-material';
import { debounce } from 'lodash';
import { useMemo, useState } from 'react';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import IconButton from '../IconButton';
import MessageBox from '../MessageBox';
import OutlinedInput from '../OutlinedInput';
import { Panel, PanelHeader } from '../Panels';
import ProvisionServerDialog from '../ProvisionServerDialog';
import ServerPanels from './ServerPanels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
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
  const [searchString, setSearchString] = useState<string>('');

  const [groups, setGroups] = useState<ServerGroups | undefined>();

  const [provision, setProvision] = useState<boolean>(false);

  const {
    data: servers,
    loading,
    error: fetchError,
  } = useFetch<APIServerOverviewList>('/server', {
    refreshInterval: 4000,
    onSuccess: (data) => {
      setGroups(group(data, searchString));
    },
  });

  const changeGroups = useMemo(
    () =>
      debounce((...args: Parameters<typeof group>) => {
        setGroups(group(...args));
      }, 500),
    [],
  );

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

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Servers</HeaderText>
          <IconButton
            mapPreset="add"
            onClick={() => {
              setProvision(true);
            }}
          />
          <OutlinedInput
            onChange={(event) => {
              const { value } = event.target;

              setSearchString(value);

              changeGroups(servers, value);
            }}
            startAdornment={
              <SearchIcon sx={{ color: DIVIDER, marginRight: '.4em' }} />
            }
            sx={{ width: '20em' }}
            value={searchString}
          />
        </PanelHeader>
        <ServerPanels groups={groups} servers={servers} />
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
