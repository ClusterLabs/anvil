import { Divider, Drawer, List, ListItem, Box } from '@material-ui/core';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import { Dispatch, SetStateAction } from 'react';
import { BodyText, HeaderText } from './Text';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';
import { DIVIDER } from '../lib/consts/DEFAULT_THEME';

interface DrawerProps {
  open: boolean;
  setOpen: Dispatch<SetStateAction<boolean>>;
}

const useStyles = makeStyles(() =>
  createStyles({
    list: {
      width: '200px',
      backdropFilter: 'blur(5px) opacity(0)',
    },
    container: {},
    divider: {
      background: DIVIDER,
    },
    text: {
      paddingTop: '.5em',
      paddingLeft: '1.5em',
    },
  }),
);

const AnvilDrawer = ({ open, setOpen }: DrawerProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Drawer
      BackdropProps={{ invisible: true }}
      anchor="left"
      open={open}
      onClose={() => setOpen(!open)}
    >
      <div role="presentation" className={classes.container}>
        <List className={classes.list}>
          <ListItem button>
            <HeaderText text="Admin" />
          </ListItem>
          <Divider className={classes.divider} />
          {ICONS.map(
            (icon): JSX.Element => (
              <ListItem button key={icon.image}>
                <Box display="flex" flexDirection="row" width="100%">
                  <Box>
                    <img
                      alt=""
                      key="icon"
                      src={icon.image} // eslint-disable-next-line react/jsx-props-no-spreading
                      {...ICON_SIZE}
                    />
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
    </Drawer>
  );
};

export default AnvilDrawer;
