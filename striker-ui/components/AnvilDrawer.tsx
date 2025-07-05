import MuiDashboardIcon from '@mui/icons-material/Dashboard';
import MuiLogoutIcon from '@mui/icons-material/Logout';
import MuiDrawer from '@mui/material/Drawer';
import MuiList from '@mui/material/List';
import MuiListItem from '@mui/material/ListItem';
import MuiListItemButton from '@mui/material/ListItemButton';
import styled from '@mui/material/styles/styled';
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

const StyledDrawer = styled(MuiDrawer)(() => ({
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
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
}

const AnvilDrawer = ({ open, setOpen }: DrawerProps): React.ReactElement => {
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
        <MuiList className={classes.list}>
          <MuiListItem>
            <BodyText>
              {session?.user ? (
                <>Welcome, {session.user.name}</>
              ) : (
                'Unregistered'
              )}
            </BodyText>
          </MuiListItem>
          <Divider />
          <MuiListItemButton component="a" href="/index.html">
            <FlexBox fullWidth row spacing="2em">
              <MuiDashboardIcon className={classes.actionIcon} />
              <BodyText>Dashboard</BodyText>
            </FlexBox>
          </MuiListItemButton>
          {ICONS.map(
            (icon): React.ReactElement => (
              <MuiListItemButton
                key={`anvil-drawer-${icon.image}`}
                component="a"
                href={icon.uri}
              >
                <FlexBox fullWidth row spacing="2em">
                  <img alt={icon.text} src={icon.image} {...ICON_SIZE} />
                  <BodyText>{icon.text}</BodyText>
                </FlexBox>
              </MuiListItemButton>
            ),
          )}
          <MuiListItemButton
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
              <MuiLogoutIcon className={classes.actionIcon} />
              <BodyText>Logout</BodyText>
            </FlexBox>
          </MuiListItemButton>
        </MuiList>
      </div>
    </StyledDrawer>
  );
};

export default AnvilDrawer;
