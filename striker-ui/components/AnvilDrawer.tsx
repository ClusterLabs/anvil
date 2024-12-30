import {
  Dashboard as DashboardIcon,
  Logout as LogoutIcon,
} from '@mui/icons-material';
import { Drawer, List, ListItem, ListItemButton, styled } from '@mui/material';
import { Dispatch, SetStateAction } from 'react';
import { useCookies } from 'react-cookie';

import { OLD_ICON } from '../lib/consts/DEFAULT_THEME';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';

import api from '../lib/api';
import Divider from './Divider';
import FlexBox from './FlexBox';
import handleAPIError from '../lib/handleAPIError';
import { BodyText } from './Text';

const PREFIX = 'AnvilDrawer';

const classes = {
  actionIcon: `${PREFIX}-actionIcon`,
  list: `${PREFIX}-list`,
};

const StyledDrawer = styled(Drawer)(() => ({
  [`& .${classes.list}`]: {
    width: '200px',
  },

  [`& .${classes.actionIcon}`]: {
    fontSize: '2.3em',
    color: OLD_ICON,
  },
}));

interface DrawerProps {
  open: boolean;
  setOpen: Dispatch<SetStateAction<boolean>>;
}

const AnvilDrawer = ({ open, setOpen }: DrawerProps): JSX.Element => {
  const [cookies] = useCookies(['suiapi.session']);

  const session: SessionCookie | undefined = cookies['suiapi.session'];

  return (
    <StyledDrawer
      anchor="left"
      open={open}
      onClose={() => setOpen(!open)}
      slotProps={{
        backdrop: {
          invisible: true,
        },
      }}
    >
      <div role="presentation">
        <List className={classes.list}>
          <ListItem>
            <BodyText>
              {session?.user ? (
                <>Welcome, {session.user.name}</>
              ) : (
                'Unregistered'
              )}
            </BodyText>
          </ListItem>
          <Divider />
          <ListItemButton component="a" href="/index.html">
            <FlexBox fullWidth row spacing="2em">
              <DashboardIcon className={classes.actionIcon} />
              <BodyText>Dashboard</BodyText>
            </FlexBox>
          </ListItemButton>
          {ICONS.map(
            (icon): JSX.Element => (
              <ListItemButton
                key={`anvil-drawer-${icon.image}`}
                component="a"
                href={icon.uri}
              >
                <FlexBox fullWidth row spacing="2em">
                  <img alt={icon.text} src={icon.image} {...ICON_SIZE} />
                  <BodyText>{icon.text}</BodyText>
                </FlexBox>
              </ListItemButton>
            ),
          )}
          <ListItemButton
            onClick={() => {
              api
                .put('/auth/logout')
                .then(() => {
                  window.location.replace('/login');
                })
                .catch((error) => {
                  handleAPIError(error);
                });
            }}
          >
            <FlexBox fullWidth row spacing="2em">
              <LogoutIcon className={classes.actionIcon} />
              <BodyText>Logout</BodyText>
            </FlexBox>
          </ListItemButton>
        </List>
      </div>
    </StyledDrawer>
  );
};

export default AnvilDrawer;
