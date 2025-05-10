import { Grid, gridClasses } from '@mui/material';
import { dSize, dSizeStr } from 'format-data-size';
import { FC, ReactNode, useMemo } from 'react';

import {
  toAnvilDetail,
  toAnvilMemoryCalcable,
  toAnvilSharedStorageOverview,
} from '../../lib/api_converters';
import { MemoryBar, StorageBar } from '../Bars';
import {
  toAnvilStatusColour,
  toDrbdStatusColour,
  toHostStatusColour,
} from '../../lib/colours';
import Divider from '../Divider';
import FlexBox from '../FlexBox';
import Spinner from '../Spinner';
import { BodyText, InlineMonoText, MonoText } from '../Text';
import { ago } from '../../lib/time';
import useFetch from '../../hooks/useFetch';

const AnvilSummary: FC<AnvilSummaryProps> = (props) => {
  const { anvilUuid, refreshInterval = 5000 } = props;

  const { altData: anvil, loading: loadingAnvil } = useFetch<
    AnvilListItem,
    APIAnvilDetail
  >(`/anvil/${anvilUuid}`, {
    mod: toAnvilDetail,
    refreshInterval,
  });

  const { data: cpu, loading: loadingCpu } = useFetch<AnvilCPU>(
    `/anvil/${anvilUuid}/cpu`,
    {
      refreshInterval,
    },
  );

  const cpuSubnodes = useMemo<AnvilCPU['hosts'][string][] | undefined>(
    () => cpu && Object.values(cpu.hosts),
    [cpu],
  );

  const { altData: memory, loading: loadingMemory } = useFetch<
    AnvilMemory,
    AnvilMemoryCalcable
  >(`/anvil/${anvilUuid}/memory`, {
    mod: toAnvilMemoryCalcable,
    refreshInterval,
  });

  const { altData: storages, loading: loadingStorages } = useFetch<
    APIAnvilStorageList,
    APIAnvilSharedStorageOverview
  >(`/anvil/${anvilUuid}/storage`, {
    mod: toAnvilSharedStorageOverview,
    refreshInterval,
  });

  const loading = useMemo<boolean>(
    () =>
      [loadingAnvil, loadingCpu, loadingMemory, loadingStorages].some(
        (cond) => cond,
      ),
    [loadingAnvil, loadingCpu, loadingMemory, loadingStorages],
  );

  const anvilSummary = useMemo(() => {
    if (!anvil) {
      return undefined;
    }

    const { system } = anvil.status;

    const colour = toAnvilStatusColour(system);

    return (
      <MonoText inheritColour color={colour}>
        {system}
      </MonoText>
    );
  }, [anvil]);

  const anvilDrbdSummary = useMemo(() => {
    if (!anvil) {
      return undefined;
    }

    const { maxEstimatedTimeToSync, status } = anvil.status.drbd;

    const colour = toDrbdStatusColour(status);

    let etts: string | undefined;

    if (maxEstimatedTimeToSync) {
      etts = ago(maxEstimatedTimeToSync);
    }

    return (
      <MonoText inheritColour color={colour}>
        {status}
        {etts && `(needs ~${etts})`}
      </MonoText>
    );
  }, [anvil]);

  const hostsSummary = useMemo(
    () =>
      anvil && (
        <Grid columns={1} container>
          {Object.values(anvil.hosts).map<ReactNode>((host) => {
            const { name, serverCount, state, stateProgress, uuid } = host;

            const colour = toHostStatusColour(state);

            let stateValue: string = state;

            if (!['offline', 'online'].includes(state)) {
              stateValue = `${state} (${stateProgress}%)`;
            }

            return (
              <Grid
                alignItems="center"
                columnSpacing="0.5em"
                container
                key={`subnode-${uuid}`}
              >
                <Grid item xs="auto">
                  <BodyText variant="caption" whiteSpace="nowrap">
                    {name}
                  </BodyText>
                </Grid>
                <Grid item xs="auto">
                  <MonoText inheritColour color={colour}>
                    {stateValue}
                  </MonoText>
                </Grid>
                <Grid item xs>
                  <Divider />
                </Grid>
                <Grid item xs="auto">
                  <Grid alignItems="center" columns={2} container width="4em">
                    <Grid item xs={1}>
                      <BodyText variant="caption">Servers</BodyText>
                    </Grid>
                    <Grid display="flex" item justifyContent="flex-end" xs={1}>
                      <MonoText variant="caption">{serverCount}</MonoText>
                    </Grid>
                  </Grid>
                </Grid>
              </Grid>
            );
          })}
        </Grid>
      ),
    [anvil],
  );

  const cpuSummary = useMemo(
    () =>
      cpu &&
      cpuSubnodes && (
        <FlexBox row rowSpacing=".5em">
          <BodyText variant="caption" whiteSpace="nowrap">
            Vendor{' '}
            <InlineMonoText sx={{ paddingRight: 0 }}>
              {cpuSubnodes[0].vendor}
            </InlineMonoText>
          </BodyText>
          <Divider sx={{ flexGrow: 1 }} />
          <Grid alignItems="center" columns={2} container width="4em">
            <Grid item xs={1}>
              <BodyText variant="caption">Cores</BodyText>
            </Grid>
            <Grid display="flex" item justifyContent="flex-end" xs={1}>
              <MonoText variant="caption">{cpu.cores}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText variant="caption">Threads</BodyText>
            </Grid>
            <Grid display="flex" item justifyContent="flex-end" xs={1}>
              <MonoText variant="caption">{cpu.threads}</MonoText>
            </Grid>
          </Grid>
        </FlexBox>
      ),
    [cpu, cpuSubnodes],
  );

  const memorySummary = useMemo(
    () =>
      memory && (
        <FlexBox spacing={0}>
          <FlexBox row justifyContent="flex-end">
            <BodyText variant="caption">
              Free
              <InlineMonoText>
                {
                  dSize(memory.available, {
                    toUnit: 'ibyte',
                  })?.value
                }
              </InlineMonoText>
              /
              <InlineMonoText edge="end">
                {dSizeStr(memory.total, {
                  toUnit: 'ibyte',
                })}
              </InlineMonoText>
            </BodyText>
          </FlexBox>
          <MemoryBar memory={memory} thin />
        </FlexBox>
      ),
    [memory],
  );

  const storeSummary = useMemo(
    () =>
      storages && (
        <FlexBox spacing={0}>
          <FlexBox row justifyContent="flex-end">
            <BodyText variant="caption">
              Total free
              <InlineMonoText>
                {
                  dSize(storages.totalFree, {
                    toUnit: 'ibyte',
                  })?.value
                }
              </InlineMonoText>
              /
              <InlineMonoText edge="end">
                {dSizeStr(storages.totalSize, {
                  toUnit: 'ibyte',
                })}
              </InlineMonoText>
            </BodyText>
          </FlexBox>
          <StorageBar storages={storages} thin />
        </FlexBox>
      ),
    [storages],
  );

  return loading ? (
    <Spinner mt={0} />
  ) : (
    <Grid
      alignItems="center"
      columns={4}
      container
      sx={{
        [`& > .${gridClasses.item}:nth-child(odd)`]: {
          alignItems: 'center',
          display: 'flex',
          height: '2.2em',
        },
      }}
    >
      <Grid item xs={1}>
        <BodyText>Status</BodyText>
      </Grid>
      <Grid item xs={3}>
        {anvilSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Replication</BodyText>
      </Grid>
      <Grid item xs={3}>
        {anvilDrbdSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Subnodes</BodyText>
      </Grid>
      <Grid item xs={3}>
        {hostsSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>CPU</BodyText>
      </Grid>
      <Grid item xs={3}>
        {cpuSummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Memory</BodyText>
      </Grid>
      <Grid item xs={3}>
        {memorySummary}
      </Grid>
      <Grid item xs={1}>
        <BodyText>Storage</BodyText>
      </Grid>
      <Grid item xs={3}>
        {storeSummary}
      </Grid>
    </Grid>
  );
};

export default AnvilSummary;
