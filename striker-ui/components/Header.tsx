import { useState } from 'react';
import { styled } from '@mui/material/styles';
import { AppBar, Box, Button } from '@mui/material';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';
import { BORDER_RADIUS, RED } from '../lib/consts/DEFAULT_THEME';
import AnvilDrawer from './AnvilDrawer';

const PREFIX = 'Header';

const classes = {
  input: `${PREFIX}-input`,
  barElement: `${PREFIX}-barElement`,
  iconBox: `${PREFIX}-iconBox`,
  searchBar: `${PREFIX}-searchBar`,
  icons: `${PREFIX}-icons`,
};

const StyledAppBar = styled(AppBar)(({ theme }) => ({
  paddingTop: theme.spacing(0.5),
  paddingBottom: theme.spacing(0.5),
  paddingLeft: theme.spacing(3),
  paddingRight: theme.spacing(3),
  borderBottom: 'solid 1px',
  borderBottomColor: RED,
  position: 'static',

  [`& .${classes.input}`]: {
    height: '2.8em',
    width: '30vw',
    backgroundColor: theme.palette.secondary.main,
    borderRadius: BORDER_RADIUS,
  },

  [`& .${classes.barElement}`]: {
    padding: 0,
  },

  [`& .${classes.iconBox}`]: {
    [theme.breakpoints.down('sm')]: {
      display: 'none',
    },
  },

  [`& .${classes.searchBar}`]: {
    [theme.breakpoints.down('sm')]: {
      flexGrow: 1,
      paddingLeft: '15vw',
    },
  },

  [`& .${classes.icons}`]: {
    paddingLeft: '.1em',
    paddingRight: '.1em',
  },
}));

const Header = (): JSX.Element => {
  const [open, setOpen] = useState(false);

  const toggleDrawer = (): void => setOpen(!open);

  return (
    <StyledAppBar>
      <Box display="flex" justifyContent="space-between" flexDirection="row">
        <Box className={classes.barElement}>
          <Button onClick={toggleDrawer}>
            <img alt="" src="/pngs/logo.png" width="160" height="40" />
          </Button>
        </Box>
        <Box className={`${classes.barElement} ${classes.iconBox}`}>
          {ICONS.map(
            (icon): JSX.Element => (
              <a
                key={icon.uri}
                href={
                  icon.uri.search(/^https?:/) !== -1
                    ? icon.uri
                    : `${process.env.NEXT_PUBLIC_API_URL}${icon.uri}`
                }
              >
                <img
                  alt=""
                  key="icon"
                  src={icon.image}
                  // eslint-disable-next-line react/jsx-props-no-spreading
                  {...ICON_SIZE}
                  className={classes.icons}
                />
              </a>
            ),
          )}
        </Box>
      </Box>
      <AnvilDrawer open={open} setOpen={setOpen} />
    </StyledAppBar>
  );
};

export default Header;
