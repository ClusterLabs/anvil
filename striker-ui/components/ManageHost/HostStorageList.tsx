import { Grid, gridClasses } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { StorageBar } from '../Bars';
import Divider from '../Divider';
import { BodyText, InlineMonoText, MonoText } from '../Text';

const HostStorageList: React.FC<HostStorageListProps> = (props) => {
  const { host } = props;

  const { volumeGroups, volumeGroupTotals } = host.storage;

  const total = useMemo(() => {
    const { free: nFree, size: nSize, used: nUsed } = volumeGroupTotals;

    const free = dSizeStr(nFree, { toUnit: 'ibyte' });
    const size = dSizeStr(nSize, { toUnit: 'ibyte' });
    const used = dSizeStr(nUsed, { toUnit: 'ibyte' });

    return (
      <Grid item width="100%">
        <BodyText>Total</BodyText>
        <StorageBar volume={volumeGroupTotals} />
        <Grid container>
          <Grid item>
            <BodyText>Used: {used}</BodyText>
          </Grid>
          <Grid item textAlign="center" xs>
            <BodyText fontWeight={400}>Free: {free}</BodyText>
          </Grid>
          <Grid item textAlign="right">
            <BodyText>Size: {size}</BodyText>
          </Grid>
        </Grid>
      </Grid>
    );
  }, [volumeGroupTotals]);

  const vgs = useMemo(() => {
    const ls = Object.values(volumeGroups).map<React.ReactNode>((vg) => {
      const { free: nFree, internalUuid, name, size: nSize, uuid } = vg;

      const free = dSizeStr(nFree, { toUnit: 'ibyte' });
      const size = dSizeStr(nSize, { toUnit: 'ibyte' });

      return (
        <Grid item key={`vg-${uuid}`}>
          <Grid alignItems="center" container>
            <Grid item xs>
              <BodyText noWrap>{name}</BodyText>
            </Grid>
            <Grid item>
              <BodyText variant="caption">
                Free <InlineMonoText>{free}</InlineMonoText>/
                <InlineMonoText edge="end">{size}</InlineMonoText>
              </BodyText>
            </Grid>
            <Grid item width="100%">
              <StorageBar thin volume={vg} />
            </Grid>
            <Grid item width="100%">
              <MonoText noWrap variant="caption">
                {internalUuid}
              </MonoText>
            </Grid>
          </Grid>
        </Grid>
      );
    });

    return (
      <Grid item width="100%">
        <Grid
          container
          spacing="1em"
          sx={{
            [`& > .${gridClasses.item}`]: {
              width: {
                xs: '100%',
                lg: '50%',
                xl: 'calc(100% / 3)',
              },
            },
          }}
        >
          {ls}
        </Grid>
      </Grid>
    );
  }, [volumeGroups]);

  return (
    <Grid alignItems="center" container spacing="1em">
      {total}
      <Grid item>
        <BodyText>Volume Groups</BodyText>
      </Grid>
      <Grid item xs>
        <Divider />
      </Grid>
      {vgs}
    </Grid>
  );
};

export default HostStorageList;
