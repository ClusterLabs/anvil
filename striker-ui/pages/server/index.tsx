import { useState } from 'react';
import { useRouter } from 'next/router';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import { FullSize, Preview } from '../../components/Display';
import Header from '../../components/Header';

const useStyles = makeStyles((theme) => ({
  child: {
    width: '18%',
    height: '100%',
    [theme.breakpoints.down('lg')]: {
      width: '25%',
    },
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },
  server: {
    width: '35%',
    [theme.breakpoints.down('lg')]: {
      width: '25%',
    },
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },
  container: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-between',
    [theme.breakpoints.down('md')]: {
      display: 'block',
    },
  },
}));

const Server = (): JSX.Element => {
  const [previewMode, setPreviewMode] = useState<boolean>(true);
  const classes = useStyles();

  const router = useRouter();
  const { uuid } = router.query;

  return (
    <>
      <Header />
      {typeof uuid === 'string' &&
        (previewMode ? (
          <Box className={classes.container}>
            <Box className={classes.child}>
              <Preview setMode={setPreviewMode} />
            </Box>
          </Box>
        ) : (
          <Box className={classes.container}>
            <FullSize setMode={setPreviewMode} uuid={uuid} />
          </Box>
        ))}
    </>
  );
};

export default Server;
