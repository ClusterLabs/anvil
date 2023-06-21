import { Dashboard as DashboardIcon } from '@mui/icons-material';
import {
  Box,
  Divider,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  styled,
} from '@mui/material';
import { Dispatch, SetStateAction } from 'react';

import { DIVIDER, GREY } from '../lib/consts/DEFAULT_THEME';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';

import { BodyText } from './Text';
import useCookieJar from '../hooks/useCookieJar';

const PREFIX = 'AnvilDrawer';

const classes = {
  list: `${PREFIX}-list`,
  divider: `${PREFIX}-divider`,
  text: `${PREFIX}-text`,
  dashboardButton: `${PREFIX}-dashboardButton`,
  dashboardIcon: `${PREFIX}-dashboardIcon`,
};

const StyledDrawer = styled(Drawer)(() => ({
  [`& .${classes.list}`]: {
    width: '200px',
  },

  [`& .${classes.divider}`]: {
    backgroundColor: DIVIDER,
  },

  [`& .${classes.text}`]: {
    paddingTop: '.5em',
    paddingLeft: '1.5em',
  },

  [`& .${classes.dashboardButton}`]: {
    paddingLeft: '.1em',
  },

  [`& .${classes.dashboardIcon}`]: {
    fontSize: '2.3em',
    color: GREY,
  },
}));

interface DrawerProps {
  open: boolean;
  setOpen: Dispatch<SetStateAction<boolean>>;
}

const AnvilDrawer = ({ open, setOpen }: DrawerProps): JSX.Element => {
  const { getSessionUser } = useCookieJar();

  const sessionUser = getSessionUser();

  return (
    <StyledDrawer
      BackdropProps={{ invisible: true }}
      anchor="left"
      open={open}
      onClose={() => setOpen(!open)}
    >
      <div role="presentation">
        <List className={classes.list}>
          <ListItem>
            <BodyText>
              {sessionUser ? <>Welcome, {sessionUser.name}</> : 'Unregistered'}
            </BodyText>
          </ListItem>
          <Divider className={classes.divider} />
          <ListItemButton component="a" href="/index.html">
            <Box display="flex" flexDirection="row" width="100%">
              <Box className={classes.dashboardButton}>
                <DashboardIcon className={classes.dashboardIcon} />
              </Box>
              <Box flexGrow={1} className={classes.text}>
                <BodyText text="Dashboard" />
              </Box>
            </Box>
          </ListItemButton>
          {ICONS.map(
            (icon): JSX.Element => (
              <ListItemButton key={icon.image} component="a" href={icon.uri}>
                <Box display="flex" flexDirection="row" width="100%">
                  <Box>
                    <img alt="" key="icon" src={icon.image} {...ICON_SIZE} />
                  </Box>
                  <Box flexGrow={1} className={classes.text}>
                    <BodyText text={icon.text} />
                  </Box>
                </Box>
              </ListItemButton>
            ),
          )}
        </List>
      </div>
    </StyledDrawer>
  );
};

export default AnvilDrawer;
