import { useContext } from 'react';
import Box from '@mui/material/Box';
import Switch from '@mui/material/Switch';
import { styled } from '@mui/material/styles';
import { HeaderText } from '../Text';
import anvilState from '../../lib/consts/ANVILS';
import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import putFetch from '../../lib/fetchers/putFetch';

const PREFIX = 'SelectedAnvil';

const classes = {
  root: `${PREFIX}-root`,
  anvilName: `${PREFIX}-anvilName`,
};

const StyledBox = styled(Box)(() => ({
  [`&.${classes.root}`]: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
  },

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
    <StyledBox className={classes.root}>
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
              onChange={() =>
                putFetch(`${process.env.NEXT_PUBLIC_API_URL}/set_power`, {
                  anvil_uuid: list[index].anvil_uuid,
                  is_on: !isAnvilOn(list[index]),
                })
              }
            />
          </Box>
        </>
      )}
    </StyledBox>
  );
};

export default SelectedAnvil;
