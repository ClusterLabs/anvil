import { Box as MuiBox, styled } from '@mui/material';
import Head from 'next/head';
import { NextRouter, useRouter } from 'next/router';
import { createElement, useContext, useMemo } from 'react';

import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

import AnvilProvider, { AnvilContext } from '../../components/AnvilContext';
import Anvils from '../../components/Anvils';
import CPU from '../../components/CPU';
import Header from '../../components/Header';
import Hosts from '../../components/Hosts';
import Memory from '../../components/Memory';
import MessageBox from '../../components/MessageBox';
import Network from '../../components/Network';
import { Panel } from '../../components/Panels';
import Servers from '../../components/Servers';
import SharedStorage from '../../components/SharedStorage';
import Spinner from '../../components/Spinner';
import useFetch from '../../hooks/useFetch';
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

const CenterPanel: React.FC<React.PropsWithChildren> = (props) => {
  const { children } = props;

  return createElement(
    Panel,
    {
      sx: {
        marginLeft: { xs: '1em', sm: 'auto' },
        marginRight: { xs: '1em', sm: 'auto' },
        marginTop: 'calc(50vh - 10em)',
        maxWidth: { xs: undefined, sm: '60%', md: '50%', lg: '40%' },
        minWidth: 'fit-content',
      },
    },
    children,
  );
};

const getAnvilUuid = (router: NextRouter, list?: AnvilList): string => {
  if ([router.isReady, list].some((v) => !v)) {
    return '';
  }

  const { anvils: ls } = list as AnvilList;

  const { name, uuid } = router.query;

  let anvil: AnvilListItem | undefined;

  if (name) {
    anvil = ls.find((li) => li.anvil_name === name);
  } else if (uuid) {
    anvil = ls.find((li) => li.anvil_uuid === uuid);
  }

  if (anvil) {
    return anvil.anvil_uuid;
  }

  const [first = { anvil_uuid: '' }] = ls;

  return first.anvil_uuid;
};

const AnvilSelector: React.FC<
  React.PropsWithChildren<{
    list?: AnvilList;
    loading: boolean;
  }>
> = (props) => {
  const { children, list, loading } = props;

  const router = useRouter();

  const { uuid: selected, setAnvilUuid } = useContext(AnvilContext);

  const translated = useMemo(() => {
    const value = getAnvilUuid(router, list);

    setAnvilUuid?.call(null, value);

    return value;
  }, [list, router, setAnvilUuid]);

  if (selected) {
    return children;
  }

  const loadingElement = (
    <CenterPanel>
      <Spinner sx={{ margin: '2em 2.4em' }} />
    </CenterPanel>
  );

  const failedElement = (
    <CenterPanel>
      <MessageBox type="warning">Failed to get system summary.</MessageBox>
    </CenterPanel>
  );

  if (loading) {
    return loadingElement;
  }

  if (!list) {
    return failedElement;
  }

  if (!translated) {
    return failedElement;
  }

  return loadingElement;
};

const Anvil: React.FC = () => {
  const width = useWindowDimensions();

  const { data: summary, loading: loadingSummary } = useFetch<AnvilList>(
    `/anvil/summary`,
    {
      periodic: true,
    },
  );

  const contentLayoutElement = useMemo(() => {
    if (!summary || !width) {
      return undefined;
    }

    if (width > LARGE_MOBILE_BREAKPOINT) {
      return (
        <MuiBox className={classes.container}>
          <MuiBox className={classes.child}>
            <Anvils list={summary} />
            <Hosts anvil={summary.anvils} />
          </MuiBox>
          <MuiBox className={classes.server}>
            <Servers anvil={summary.anvils} />
          </MuiBox>
          <MuiBox className={classes.child}>
            <SharedStorage />
          </MuiBox>
          <MuiBox className={classes.child}>
            <Network />
            <CPU />
            <Memory />
          </MuiBox>
        </MuiBox>
      );
    }

    return (
      <MuiBox className={classes.container}>
        <MuiBox className={classes.child}>
          <Servers anvil={summary.anvils} />
          <Anvils list={summary} />
          <Hosts anvil={summary.anvils} />
        </MuiBox>
        <MuiBox className={classes.child}>
          <Network />
          <SharedStorage />
          <CPU />
          <Memory />
        </MuiBox>
      </MuiBox>
    );
  }, [summary, width]);

  return (
    <StyledDiv>
      <Head>
        <title>Anvil</title>
      </Head>
      <Header />
      <AnvilProvider>
        <AnvilSelector list={summary} loading={loadingSummary}>
          {contentLayoutElement}
        </AnvilSelector>
      </AnvilProvider>
    </StyledDiv>
  );
};

export default Anvil;
