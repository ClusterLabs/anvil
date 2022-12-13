import { Box, Divider, Drawer, List, ListItem } from '@mui/material';
import { styled } from '@mui/material/styles';
import DashboardIcon from '@mui/icons-material/Dashboard';
import { Dispatch, SetStateAction } from 'react';
import { BodyText, HeaderText } from './Text';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';
import { DIVIDER, GREY } from '../lib/consts/DEFAULT_THEME';

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

const AnvilDrawer = ({ open, setOpen }: DrawerProps): JSX.Element => (
  <StyledDrawer
    BackdropProps={{ invisible: true }}
    anchor="left"
    open={open}
    onClose={() => setOpen(!open)}
  >
    <div role="presentation">
      <List className={classes.list}>
        <ListItem button>
          <HeaderText text="Admin" />
        </ListItem>
        <Divider className={classes.divider} />
        <ListItem button component="a" href="/index.html">
          <Box display="flex" flexDirection="row" width="100%">
            <Box className={classes.dashboardButton}>
              <DashboardIcon className={classes.dashboardIcon} />
            </Box>
            <Box flexGrow={1} className={classes.text}>
              <BodyText text="Dashboard" />
            </Box>
          </Box>
        </ListItem>
        {ICONS.map(
          (icon): JSX.Element => (
            <ListItem
              button
              key={icon.image}
              component="a"
              href={
                icon.uri.search(/^https?:/) !== -1
                  ? icon.uri
                  : `${process.env.NEXT_PUBLIC_API_URL}${icon.uri}`
              }
            >
              <Box display="flex" flexDirection="row" width="100%">
                <Box>
                  <img alt="" key="icon" src={icon.image} {...ICON_SIZE} />
                </Box>
                <Box flexGrow={1} className={classes.text}>
                  <BodyText text={icon.text} />
                </Box>
              </Box>
            </ListItem>
          ),
        )}
      </List>
    </div>
  </StyledDrawer>
);

export default AnvilDrawer;
