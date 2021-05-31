import { useState } from 'react';
import AppBar from '@material-ui/core/AppBar';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import { Box, Button } from '@material-ui/core';
import { ICONS, ICON_SIZE } from '../lib/consts/ICONS';
import { BORDER_RADIUS } from '../lib/consts/DEFAULT_THEME';
import AnvilDrawer from './AnvilDrawer';

const useStyles = makeStyles((theme) =>
  createStyles({
    appBar: {
      paddingTop: theme.spacing(0.5),
      paddingBottom: theme.spacing(0.5),
      paddingLeft: theme.spacing(3),
      paddingRight: theme.spacing(3),
    },
    input: {
      height: '2.8em',
      width: '30vw',
      backgroundColor: theme.palette.secondary.main,
      borderRadius: BORDER_RADIUS,
    },
    barElement: {
      padding: 0,
    },
    icons: {
      [theme.breakpoints.down('sm')]: {
        display: 'none',
      },
    },
    searchBar: {
      [theme.breakpoints.down('sm')]: {
        flexGrow: 1,
        paddingLeft: '15vw',
      },
    },
  }),
);

const Header = (): JSX.Element => {
  const classes = useStyles();
  const [open, setOpen] = useState(false);

  const toggleDrawer = (): void => setOpen(!open);

  return (
    <>
      <AppBar position="static" className={classes.appBar}>
        <Box display="flex" justifyContent="space-between" flexDirection="row">
          <Box className={classes.barElement}>
            <Button onClick={toggleDrawer}>
              <img alt="" src="/pngs/logo.png" width="160" height="40" />
            </Button>
          </Box>
          <Box className={`${classes.barElement} ${classes.searchBar}`}>
            <input className={classes.input} list="search-suggestions" />
          </Box>
          <Box className={`${classes.barElement} ${classes.icons}`}>
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
                  />
                </a>
              ),
            )}
          </Box>
        </Box>
      </AppBar>
      <AnvilDrawer open={open} setOpen={setOpen} />
    </>
  );
};

export default Header;
