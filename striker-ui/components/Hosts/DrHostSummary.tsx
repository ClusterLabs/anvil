import Grid from '@mui/material/Grid';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { toHostDetailCalcable } from '../../lib/api_converters';
import { StorageBar } from '../Bars';
import { toDrbdStatusColour, toHostStatusColour } from '../../lib/colours';
import Divider from '../Divider';
import Spinner from '../Spinner';
import { BodyText, InlineMonoText, MonoText } from '../Text';
import { ago } from '../../lib/time';
import useFetch from '../../hooks/useFetch';

const DrHostSummary: React.FC<DrHostSummaryProps> = (props) => {
  const { host, refreshInterval = 5000 } = props;

  const { altData: detail, loading } = useFetch<
    APIHostDetail,
    APIHostDetailCalcable
  >(`/host/${host.uuid}`, {
    mod: toHostDetailCalcable,
    refreshInterval,
  });

  const systemSummary = useMemo<React.ReactNode>(() => {
    if (!detail) {
      return undefined;
    }

    const { system } = detail.status;

    const colour = toHostStatusColour(system);

    return (
      <MonoText color={colour} inheritColour>
        {system}
      </MonoText>
    );
  }, [detail]);

  const drbdSummary = useMemo<React.ReactNode>(() => {
    if (!detail) {
      return undefined;
    }

    const { maxEstimatedTimeToSync, status } = detail.status.drbd;

    const colour = toDrbdStatusColour(status);

    let etts: string | undefined;

    if (maxEstimatedTimeToSync) {
      etts = ago(maxEstimatedTimeToSync);
    }

    return (
      <MonoText color={colour} inheritColour>
        {status}
        {etts && ` (estimated ~${etts})`}
      </MonoText>
    );
  }, [detail]);

  const serverSummary = useMemo<React.ReactNode>(() => {
    if (!detail) {
      return undefined;
    }

    const { configured, replicating, running } = detail.servers;

    return (
      <Grid alignItems="center" container>
        <Grid item width="100%">
          <Grid alignItems="center" columnSpacing="0.5em" container>
            <Grid item>
              <BodyText variant="caption">Configured</BodyText>
            </Grid>
            <Grid item xs>
              <Divider />
            </Grid>
            <Grid item>
              <MonoText variant="caption">{configured.length}</MonoText>
            </Grid>
          </Grid>
        </Grid>
        <Grid item width="100%">
          <Grid alignItems="center" columnSpacing="0.5em" container>
            <Grid item>
              <BodyText variant="caption">Syncing</BodyText>
            </Grid>
            <Grid item xs>
              <Divider />
            </Grid>
            <Grid item>
              <MonoText variant="caption">{replicating.length}</MonoText>
            </Grid>
          </Grid>
        </Grid>
        <Grid item width="100%">
          <Grid alignItems="center" columnSpacing="0.5em" container>
            <Grid item>
              <BodyText variant="caption">Running</BodyText>
            </Grid>
            <Grid item xs>
              <Divider />
            </Grid>
            <Grid item>
              <MonoText variant="caption">{running.length}</MonoText>
            </Grid>
          </Grid>
        </Grid>
      </Grid>
    );
  }, [detail]);

  const storageSummary = useMemo<React.ReactNode>(() => {
    if (!detail) {
      return undefined;
    }

    const { volumeGroupTotals: totals } = detail.storage;

    const free = dSizeStr(totals.free, {
      toUnit: 'ibyte',
    });

    const size = dSizeStr(totals.size, {
      toUnit: 'ibyte',
    });

    return (
      <Grid container>
        <Grid item xs />
        <Grid item>
          <BodyText variant="caption">
            Total free
            <InlineMonoText>{free}</InlineMonoText>/
            <InlineMonoText edge="end">{size}</InlineMonoText>
          </BodyText>
        </Grid>
        <Grid item width="100%">
          <StorageBar thin volume={totals} />
        </Grid>
      </Grid>
    );
  }, [detail]);

  if (loading) {
    return <Spinner mt={0} />;
  }

  return (
    <Grid alignItems="center" container rowSpacing="0.5em">
      <Grid item width="25%">
        <BodyText>Status</BodyText>
      </Grid>
      <Grid item width="75%">
        {systemSummary}
      </Grid>
      <Grid item width="25%">
        <BodyText>Replication</BodyText>
      </Grid>
      <Grid item width="75%">
        {drbdSummary}
      </Grid>
      <Grid item width="25%">
        <BodyText>Servers</BodyText>
      </Grid>
      <Grid item width="75%">
        {serverSummary}
      </Grid>
      <Grid item width="25%">
        <BodyText>Storage</BodyText>
      </Grid>
      <Grid item width="75%">
        {storageSummary}
      </Grid>
    </Grid>
  );
};

export default DrHostSummary;
