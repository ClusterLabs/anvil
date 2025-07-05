import MuiBox from '@mui/material/Box';
import Head from 'next/head';

import AnvilSummaryList from '../components/Anvils/AnvilSummaryList';
import { Servers } from '../components/Dashboard';
import DrHostSummaryList from '../components/Hosts/DrHostSummaryList';
import Header from '../components/Header';

const Dashboard: React.FC = () => (
  <MuiBox>
    <Head>
      <title>Dashboard</title>
    </Head>
    <Header />
    <Servers />
    <AnvilSummaryList />
    <DrHostSummaryList />
  </MuiBox>
);

export default Dashboard;
