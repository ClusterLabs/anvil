import { Box } from '@mui/material';
import Head from 'next/head';

import AnvilSummaryList from '../components/Anvils/AnvilSummaryList';
import { Servers } from '../components/Dashboard';
import DrHostSummaryList from '../components/Hosts/DrHostSummaryList';
import Header from '../components/Header';

const Dashboard: React.FC = () => (
  <Box>
    <Head>
      <title>Dashboard</title>
    </Head>
    <Header />
    <Servers />
    <AnvilSummaryList />
    <DrHostSummaryList />
  </Box>
);

export default Dashboard;
