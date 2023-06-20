import { Box, styled, Switch } from '@mui/material';
import { useContext } from 'react';

import anvilState from '../../lib/consts/ANVILS';
import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import putFetch from '../../lib/fetchers/putFetch';
import { HeaderText } from '../Text';

const PREFIX = 'SelectedAnvil';

const classes = {
  anvilName: `${PREFIX}-anvilName`,
};

const StyledBox = styled(Box)(() => ({
  display: 'flex',
  flexDirection: 'row',
  width: '100%',

  [`& .${classes.anvilName}`]: {
    paddingLeft: 0,
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'optimal':
      return 'ok';
    case 'not_ready':
      return 'warning';
    case 'degraded':
      return 'error';
    default:
      return 'error';
  }
};

const isAnvilOn = (anvil: AnvilListItem): boolean =>
  !(
    anvil.hosts.findIndex(
      ({ state }: AnvilStatusHost) => state !== 'offline',
    ) === -1
  );

const SelectedAnvil = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const index = list.findIndex(
    (anvil: AnvilListItem) => anvil.anvil_uuid === uuid,
  );

  return (
    <StyledBox>
      {uuid !== '' && (
        <>
          <Box p={1}>
            <Decorator colour={selectDecorator(list[index].anvil_state)} />
          </Box>
          <Box p={1} flexGrow={1} className={classes.anvilName}>
            <HeaderText text={list[index].anvil_name} />
            <HeaderText
              text={
                anvilState.get(list[index].anvil_state) || 'State unavailable'
              }
            />
          </Box>
          <Box p={1}>
            <Switch
              checked={isAnvilOn(list[index])}
              onChange={() => {
                const { [index]: litem } = list;
                const { anvil_uuid: auuid } = litem;

                putFetch(
                  `${API_BASE_URL}/command/${
                    isAnvilOn(litem) ? 'stop-an' : 'start-an'
                  }/${auuid}`,
                  {},
                );
              }}
            />
          </Box>
        </>
      )}
    </StyledBox>
  );
};

export default SelectedAnvil;
