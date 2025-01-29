import { styled } from '@mui/material/styles';
import { List, Box, Divider, ListItemButton } from '@mui/material';
import { useRouter } from 'next/router';

import {
  HOVER,
  DIVIDER,
  LARGE_MOBILE_BREAKPOINT,
} from '../../lib/consts/DEFAULT_THEME';

import Anvil from './Anvil';
import Decorator, { Colours } from '../Decorator';
import setQueryParam from '../../lib/setQueryParam';

const PREFIX = 'AnvilList';

const classes = {
  root: `${PREFIX}-root`,
  divider: `${PREFIX}-divider`,
  button: `${PREFIX}-button`,
  anvil: `${PREFIX}-anvil`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.root}`]: {
    width: '100%',
    overflow: 'auto',
    height: '30vh',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
      overflow: 'hidden',
    },
  },

  [`& .${classes.divider}`]: {
    backgroundColor: DIVIDER,
  },

  [`& .${classes.button}`]: {
    '&:hover': {
      backgroundColor: HOVER,
    },
    paddingLeft: 0,
  },

  [`& .${classes.anvil}`]: {
    paddingLeft: 0,
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'optimal':
      return 'ok';
    case 'degraded':
      return 'warning';
    default:
      return 'off';
  }
};

const AnvilList = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const router = useRouter();

  return (
    <StyledDiv>
      <List
        component="nav"
        className={classes.root}
        aria-label="mailbox folders"
      >
        {list.map((anvil) => (
          <>
            <Divider className={classes.divider} />
            <ListItemButton
              className={classes.button}
              key={anvil.anvil_uuid}
              onClick={() => {
                const query = setQueryParam(router, 'name', anvil.anvil_name);

                router.replace({ query }, undefined, { shallow: true });
              }}
            >
              <Box display="flex" flexDirection="row" width="100%">
                <Box p={1}>
                  <Decorator
                    colour={selectDecorator(anvil.anvilStatus.system)}
                  />
                </Box>
                <Box p={1} flexGrow={1} className={classes.anvil}>
                  <Anvil anvil={anvil} />
                </Box>
              </Box>
            </ListItemButton>
          </>
        ))}
      </List>
    </StyledDiv>
  );
};

export default AnvilList;
