import AppBar from '@material-ui/core/AppBar';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import { Box } from '@material-ui/core';
import Image from 'next/image';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';

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
      width: '30vw',
      backgroundColor: theme.palette.secondary.main,
      borderRadius: '3px',
    },
    barElement: {
      padding: '0',
    },
  }),
);

const Header = (): JSX.Element => {
  const classes = useStyles();
  return (
    <AppBar position="static" className={classes.appBar}>
      <Box display="flex" justifyContent="space-between" flexDirection="row">
        <Box className={classes.barElement}>
          <Image src="/pngs/logo.png" width="160" height="40" />
        </Box>
        <Box className={classes.barElement}>
          <input className={classes.input} list="search-suggestions" />
        </Box>
        <Box className={classes.barElement}>
          {ICONS.map(
            (icon): JSX.Element => (
              <Image
                key="icon"
                src={icon} // eslint-disable-next-line react/jsx-props-no-spreading
                {...ICON_SIZE}
              />
            ),
          )}
        </Box>
      </Box>
    </AppBar>
  );
};

export default Header;
