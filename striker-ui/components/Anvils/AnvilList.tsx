import {
  Box as MuiBox,
  Divider as MuiDivider,
  List as MuiList,
  ListItemButton as MuiListItemButton,
  styled,
} from '@mui/material';
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

const AnvilList: React.FC<{ list: AnvilListItem[] }> = (props) => {
  const { list } = props;

  const router = useRouter();

  return (
    <StyledDiv>
      <MuiList
        component="nav"
        className={classes.root}
        aria-label="mailbox folders"
      >
        {list.map((anvil) => (
          <>
            <MuiDivider className={classes.divider} />
            <MuiListItemButton
              className={classes.button}
              key={anvil.anvil_uuid}
              onClick={() => {
                const query = setQueryParam(router, 'name', anvil.anvil_name);

                router.replace({ query }, undefined, { shallow: true });
              }}
            >
              <MuiBox display="flex" flexDirection="row" width="100%">
                <MuiBox p={1}>
                  <Decorator
                    colour={selectDecorator(anvil.anvilStatus.system)}
                  />
                </MuiBox>
                <MuiBox p={1} flexGrow={1} className={classes.anvil}>
                  <Anvil anvil={anvil} />
                </MuiBox>
              </MuiBox>
            </MuiListItemButton>
          </>
        ))}
      </MuiList>
    </StyledDiv>
  );
};

export default AnvilList;
