import Head from 'next/head';
import { FC } from 'react';

import Grid from '../../components/Grid';
import Header from '../../components/Header';
import PrepareNetworkForm from '../../components/PrepareNetworkForm';

const PrepareNetwork: FC = () => (
  <>
    <Head>
      <title>Prepare Network</title>
    </Head>
    <Header />
    <Grid
      columns={{ xs: 1, sm: 6, md: 4 }}
      layout={{
        'preparehost-left-column': { sm: 1, xs: 0 },
        'preparehost-center-column': {
          children: <PrepareNetworkForm />,
          md: 2,
          sm: 4,
          xs: 1,
        },
      }}
    />
  </>
);

export default PrepareNetwork;
