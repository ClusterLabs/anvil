import { Box } from '@mui/material';
import Head from 'next/head';

import AnvilSummaryList from '../components/Anvils/AnvilSummaryList';
import Header from '../components/Header';
import { Servers } from '../components/Dashboard';

const Dashboard: React.FC = () => (
  <Box>
    <Head>
      <title>Dashboard</title>
    </Head>
    <Header />
    <Servers />
    <AnvilSummaryList />
  </Box>
);

export default Dashboard;
