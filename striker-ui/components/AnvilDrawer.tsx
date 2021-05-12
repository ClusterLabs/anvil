import { Drawer, List, ListItem } from '@material-ui/core';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import { Dispatch, SetStateAction } from 'react';
import { BodyText } from './Text';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';

interface DrawerProps {
  open: boolean;
  setOpen: Dispatch<SetStateAction<boolean>>;
}

const useStyles = makeStyles(() =>
  createStyles({
    list: {
      width: '15vw',
      backdropFilter: 'blur(10px)',
      opacity: 0.7,
    },
  }),
);

const AnvilDrawer = ({ open, setOpen }: DrawerProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Drawer anchor="left" open={open} onClose={() => setOpen(!open)}>
      <div role="presentation">
        <List className={classes.list}>
          {ICONS.map(
            (icon): JSX.Element => (
              <ListItem button key={icon.image}>
                <img
                  alt=""
                  key="icon"
                  src={icon.image} // eslint-disable-next-line react/jsx-props-no-spreading
                  {...ICON_SIZE}
                />
                <BodyText text={icon.text} />
              </ListItem>
            ),
          )}
        </List>
      </div>
    </Drawer>
  );
};

export default AnvilDrawer;
