import Head from 'next/head';
import { FC } from 'react';

import GatePanel from '../../components/GatePanel';
import Header from '../../components/Header';

const Login: FC = () => (
  <>
    <Head>
      <title>Login</title>
    </Head>
    <Header />
    <GatePanel />
  </>
);

export default Login;
