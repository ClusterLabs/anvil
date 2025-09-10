import MuiGrid from '@mui/material/Grid2';

import Decorator, { Colours } from '../Decorator';
import Divider from '../Divider';
import { BodyText, MonoText } from '../Text';
import { ago, now } from '../../lib/time';

const MAP_TO_DECORATOR_COLOUR: Record<string, Colours> = {
  online: 'ok',
  'powered off': 'off',
};

const MAP_TO_HOST_TYPE_DISPLAY: Record<string, string> = {
  dr: 'DR',
  node: 'Subnode',
};

const HostListItem: React.FC<HostListItemProps> = (props) => {
  const { data } = props;

  const { hostName, hostStatus, hostType, modified, shortHostName } = data;

  const nao = now();

  return (
    <MuiGrid alignItems="center" container spacing="0.5em" width="100%">
      <MuiGrid alignSelf="stretch">
        <Decorator colour={MAP_TO_DECORATOR_COLOUR[hostStatus] || 'warning'} />
      </MuiGrid>
      <MuiGrid size="grow">
        <MuiGrid columnSpacing="0.5em" container width="100%">
          <MuiGrid>
            <BodyText noWrap>{MAP_TO_HOST_TYPE_DISPLAY[hostType]}</BodyText>
          </MuiGrid>
          <MuiGrid>
            <MonoText noWrap>{shortHostName}</MonoText>
          </MuiGrid>
          <MuiGrid
            display={{
              xs: 'none',
              md: 'flex',
            }}
          >
            <Divider flexItem orientation="vertical" />
          </MuiGrid>
          <MuiGrid
            display={{
              xs: 'none',
              md: 'flex',
            }}
          >
            <MonoText noWrap>{hostName}</MonoText>
          </MuiGrid>
        </MuiGrid>
        <BodyText noWrap>{hostStatus}</BodyText>
      </MuiGrid>
      <MuiGrid>
        <BodyText noWrap>Last changed: {ago(nao - modified)} ago</BodyText>
      </MuiGrid>
    </MuiGrid>
  );
};

export default HostListItem;
