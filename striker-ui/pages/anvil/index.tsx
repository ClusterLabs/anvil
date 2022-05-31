import Head from 'next/head';
import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';

import Anvils from '../../components/Anvils';
import Hosts from '../../components/Hosts';
import CPU from '../../components/CPU';
import SharedStorage from '../../components/SharedStorage';
import Memory from '../../components/Memory';
import Network from '../../components/Network';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Servers from '../../components/Servers';
import Header from '../../components/Header';
import AnvilProvider from '../../components/AnvilContext';
import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';
import useWindowDimensions from '../../hooks/useWindowDimenions';

const PREFIX = 'Anvil';

const classes = {
  child: `${PREFIX}-child`,
  server: `${PREFIX}-server`,
  container: `${PREFIX}-container`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.child}`]: {
    width: '22%',
    height: '100%',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      width: '50%',
    },
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },

  [`& .${classes.server}`]: {
    width: '35%',
    height: '100%',
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },

  [`& .${classes.container}`]: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-between',
    [theme.breakpoints.down('md')]: {
      display: 'block',
    },
  },
}));

const Anvil = (): JSX.Element => {
  const width = useWindowDimensions();

  const { data } = periodicFetch<AnvilList>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_anvils`,
  );

  return (
    <StyledDiv>
      <Head>
        <title>Anvil</title>
      </Head>
      <AnvilProvider>
        <Header />
        {data?.anvils &&
          width &&
          (width > LARGE_MOBILE_BREAKPOINT ? (
            <Box className={classes.container}>
              <Box className={classes.child}>
                <Anvils list={data} />
                <Hosts anvil={data.anvils} />
              </Box>
              <Box className={classes.server}>
                <Servers anvil={data.anvils} />
              </Box>
              <Box className={classes.child}>
                <SharedStorage />
              </Box>
              <Box className={classes.child}>
                <Network />
                <CPU />
                <Memory />
              </Box>
            </Box>
          ) : (
            <Box className={classes.container}>
              <Box className={classes.child}>
                <Servers anvil={data.anvils} />
                <Anvils list={data} />
                <Hosts anvil={data.anvils} />
              </Box>
              <Box className={classes.child}>
                <Network />
                <SharedStorage />
                <CPU />
                <Memory />
              </Box>
            </Box>
          ))}
      </AnvilProvider>
    </StyledDiv>
  );
};

export default Anvil;
