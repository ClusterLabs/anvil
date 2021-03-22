import AppBar from '@material-ui/core/AppBar';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import { Grid } from '@material-ui/core';
import Image from 'next/image';
import { ICONS, ICON_SIZE } from '../../lib/consts/ICONS';

const useStyles = makeStyles((theme) =>
  createStyles({
    appBar: {
      paddingTop: theme.spacing(0.5),
      paddingBottom: theme.spacing(0.5),
      paddingLeft: theme.spacing(3),
      paddingRight: theme.spacing(3),
    },
    input: {
      height: '40px',
      width: '500px',
      backgroundColor: theme.palette.secondary.main,
      borderRadius: '3px',
    },
  }),
);

const Header = (): JSX.Element => {
  const classes = useStyles();
  return (
    <AppBar position="static" className={classes.appBar}>
      <Grid container alignItems="center" justify="space-between">
        <Grid item>
          <Image src="/pngs/logo.png" width="160" height="40" />
        </Grid>
        <Grid item>
          <input className={classes.input} list="search-suggestions" />
        </Grid>
        <Grid item>
          {ICONS.map(
            (icon): JSX.Element => (
              <Image
                key="icon"
                src={icon} // eslint-disable-next-line react/jsx-props-no-spreading
                {...ICON_SIZE}
              />
            ),
          )}
        </Grid>
      </Grid>
    </AppBar>
  );
};

export default Header;
