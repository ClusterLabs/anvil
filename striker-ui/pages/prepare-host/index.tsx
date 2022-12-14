import Head from 'next/head';
import { FC } from 'react';

import Header from '../../components/Header';
import Grid from '../../components/Grid';
import PrepareHostForm from '../../components/PrepareHostForm';

const PrepareHost: FC = () => (
  <>
    <Head>
      <title>Prepare Host</title>
    </Head>
    <Header />
    <Grid
      columns={{ xs: 1, sm: 6, md: 4 }}
      layout={{
        'preparehost-left-column': { sm: 1, xs: 0 },
        'preparehost-center-column': {
          children: <PrepareHostForm />,
          md: 2,
          sm: 4,
          xs: 1,
        },
      }}
    />
  </>
);

export default PrepareHost;
