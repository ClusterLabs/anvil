import { Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { BodyText, InlineMonoText } from '../Text';

const ProvisionServerSummary: React.FC<ProvisionServerSummary> = (props) => {
  const { lsos, resources, values: server } = props;

  const disks = useMemo(
    () => ({
      ids: Object.keys(server.disks),
    }),
    [server.disks],
  );

  const node = useMemo(
    () => resources.nodes[server.node as string],
    [resources.nodes, server.node],
  );

  return (
    <Grid container rowSpacing="0.5em">
      <Grid item width="100%">
        <BodyText>
          Server <InlineMonoText>{server.name}</InlineMonoText> will be created
          on node <InlineMonoText>{node.name}</InlineMonoText> with the
          following properties:
        </BodyText>
      </Grid>
      <Grid item width="30%">
        <BodyText>CPU</BodyText>
      </Grid>
      <Grid item width="70%">
        <BodyText>
          <InlineMonoText edge="start">{server.cpu.cores}</InlineMonoText>{' '}
          core(s) of <InlineMonoText>{node.cpu.cores.total}</InlineMonoText>{' '}
          available
        </BodyText>
      </Grid>
      <Grid item width="30%">
        <BodyText>Memory</BodyText>
      </Grid>
      <Grid item width="70%">
        <BodyText>
          <InlineMonoText edge="start">
            {server.memory.value} {server.memory.unit}
          </InlineMonoText>{' '}
          of{' '}
          <InlineMonoText>
            {dSizeStr(node.memory.available, {
              toUnit: 'ibyte',
            })}
          </InlineMonoText>{' '}
          available
        </BodyText>
      </Grid>
      {...disks.ids.reduce<React.ReactNode[]>((elements, diskId) => {
        const { [diskId]: disk } = server.disks;

        const prefix = `disk-${diskId}-sum`;

        const { [disk.storageGroup as string]: sg } = resources.storageGroups;

        elements.push(
          <Grid item key={`${prefix}-label`} width="30%">
            <BodyText>
              Disk <InlineMonoText>{diskId}</InlineMonoText>
            </BodyText>
          </Grid>,
          <Grid item key={`${prefix}-value`} width="70%">
            <BodyText>
              <InlineMonoText edge="start">
                {disk.size.value} {disk.size.unit}
              </InlineMonoText>{' '}
              of{' '}
              <InlineMonoText>
                {dSizeStr(sg.usage.free, {
                  toUnit: 'ibyte',
                })}
              </InlineMonoText>{' '}
              free on <InlineMonoText>{sg.name}</InlineMonoText>
            </BodyText>
          </Grid>,
        );

        return elements;
      }, [])}
      <Grid item width="30%">
        <BodyText>Install ISO</BodyText>
      </Grid>
      <Grid item width="70%">
        <BodyText>
          <InlineMonoText edge="start">
            {resources.files[server.install as string].name}
          </InlineMonoText>
        </BodyText>
      </Grid>
      <Grid item width="30%">
        <BodyText>Driver ISO</BodyText>
      </Grid>
      <Grid item width="70%">
        <BodyText>
          <InlineMonoText edge="start">
            {server.driver ? resources.files[server.driver].name : 'none'}
          </InlineMonoText>
        </BodyText>
      </Grid>
      <Grid item width="30%">
        <BodyText>Optimize for</BodyText>
      </Grid>
      <Grid item width="70%">
        <BodyText>
          <InlineMonoText edge="start">
            {lsos[server.os as string]}
          </InlineMonoText>
        </BodyText>
      </Grid>
    </Grid>
  );
};

export default ProvisionServerSummary;
