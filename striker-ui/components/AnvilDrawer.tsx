import { Drawer, List, ListItem } from '@material-ui/core';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import { Dispatch, SetStateAction } from 'react';
import { BodyText } from './Text';

interface DrawerProps {
  open: boolean;
  setOpen: Dispatch<SetStateAction<boolean>>;
}

const useStyles = makeStyles(() =>
  createStyles({
    list: {
      width: 'auto',
    },
  }),
);

const AnvilDrawer = ({ open, setOpen }: DrawerProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Drawer anchor="left" open={open} onClose={() => setOpen(!open)}>
      <div role="presentation" className={classes.list}>
        <List>
          <ListItem button>
            <BodyText text="Button" />
          </ListItem>
        </List>
      </div>
    </Drawer>
  );
};

export default AnvilDrawer;
