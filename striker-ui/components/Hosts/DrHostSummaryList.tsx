import { Grid } from '@mui/material';
import { useMemo } from 'react';

import DrHostSummary from './DrHostSummary';
import Link from '../Link';
import {
  InnerPanel,
  InnerPanelBody,
  InnerPanelHeader,
  Panel,
  PanelHeader,
} from '../Panels';
import Spinner from '../Spinner';
import SyncIndicator from '../SyncIndicator';
import { HeaderText } from '../Text';
import useFetch from '../../hooks/useFetch';

const DrHostSummaryList: React.FC = () => {
  const {
    data: drs,
    loading,
    validating,
  } = useFetch<APIHostOverviewList>(`/host?type=dr`, {
    periodic: true,
  });

  const grid = useMemo<React.ReactNode>(() => {
    if (!drs) {
      return undefined;
    }

    const values = Object.values(drs);

    return (
      <Grid alignContent="stretch" container spacing="1em">
        {values.map<React.ReactNode>((dr) => {
          const { shortHostName: short, hostUUID: uuid } = dr;

          return (
            <Grid
              item
              key={`dr-${uuid}`}
              maxWidth={{
                xs: '100%',
                md: '50%',
                lg: 'calc(100% / 3)',
                xl: '25%',
              }}
              minWidth="24em"
              xs
            >
              <InnerPanel mv={0}>
                <InnerPanelHeader>
                  <Link href={`/host?name=${short}`} noWrap>
                    {short}
                  </Link>
                </InnerPanelHeader>
                <InnerPanelBody>
                  <DrHostSummary host={{ short, uuid }} />
                </InnerPanelBody>
              </InnerPanel>
            </Grid>
          );
        })}
      </Grid>
    );
  }, [drs]);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText>DR Hosts</HeaderText>
        <SyncIndicator syncing={validating} />
      </PanelHeader>
      {loading ? <Spinner /> : grid}
    </Panel>
  );
};

export default DrHostSummaryList;
