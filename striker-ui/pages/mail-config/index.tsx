import Grid from '@mui/material/Grid';
import Head from 'next/head';

import Header from '../../components/Header';
import { ManageMailRecipient } from '../../components/ManageMailRecipient';
import { ManageMailServer } from '../../components/ManageMailServer';
import { ExpandablePanel, Panel, PanelHeader } from '../../components/Panels';
import { HeaderText } from '../../components/Text';

const MailConfig: React.FC = () => (
  <>
    <Head>
      <title>Mail Config</title>
    </Head>
    <Header />
    <Grid container columns={{ xs: 1, md: 6, lg: 4 }}>
      <Grid item xs={1} />
      <Grid item xs={1} md={4} lg={2}>
        <Panel>
          <PanelHeader>
            <HeaderText>Mail config</HeaderText>
          </PanelHeader>
          <ExpandablePanel expandInitially header="Manage mail servers">
            <ManageMailServer />
          </ExpandablePanel>
          <ExpandablePanel expandInitially header="Manage mail recipients">
            <ManageMailRecipient />
          </ExpandablePanel>
        </Panel>
      </Grid>
    </Grid>
  </>
);

export default MailConfig;
