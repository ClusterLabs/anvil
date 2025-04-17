import { Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { StorageBar } from '../Bars';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import { BodyText, InlineMonoText } from '../Text';

const StorageGroup: React.FC<StorageGroupProps> = (props) => {
  const { storages, uuid: sgUuid } = props;

  const { [sgUuid]: storageGroup } = storages.storageGroups;

  const { name } = storageGroup;

  const sgFree = useMemo<string>(
    () => dSizeStr(storageGroup.free, { toUnit: 'ibyte' }) ?? 'none',
    [storageGroup.free],
  );

  const sgSize = useMemo<string>(
    () => dSizeStr(storageGroup.size, { toUnit: 'ibyte' }) ?? 'none',
    [storageGroup.size],
  );

  const sgUsed = useMemo<string>(
    () => dSizeStr(storageGroup.used, { toUnit: 'ibyte' }) ?? 'none',
    [storageGroup.used],
  );

  const members = useMemo<APIAnvilStorageGroupMemberCalcable[]>(
    () => Object.values(storageGroup.members),
    [storageGroup.members],
  );

  const volumeGroups = useMemo<React.ReactNode[]>(
    () =>
      members.map<React.ReactNode>((member) => {
        const { volumeGroup: vgUuid } = member;

        const { [vgUuid]: volumeGroup } = storages.volumeGroups;

        const { [volumeGroup.host]: host } = storages.hosts;

        const vgFree =
          dSizeStr(volumeGroup.free, { toUnit: 'ibyte' }) ?? 'none';

        const vgSize =
          dSizeStr(volumeGroup.size, { toUnit: 'ibyte' }) ?? 'none';

        return (
          <Grid item key={member.uuid} width="100%">
            <Grid container>
              <Grid item xs>
                <BodyText variant="caption">{host.short}</BodyText>
              </Grid>
              <Grid item textAlign="right">
                <BodyText mb="-.3em" variant="caption">
                  Free
                  <InlineMonoText>{vgFree}</InlineMonoText>/
                  <InlineMonoText>{vgSize}</InlineMonoText>
                </BodyText>
              </Grid>
              <Grid item width="100%">
                <StorageBar thin volumeGroup={volumeGroup} />
              </Grid>
            </Grid>
          </Grid>
        );
      }),
    [members, storages.hosts, storages.volumeGroups],
  );

  return (
    <InnerPanel>
      <InnerPanelHeader>
        <BodyText>{name}</BodyText>
      </InnerPanelHeader>
      <InnerPanelBody>
        <Grid container rowSpacing="1em">
          <Grid item width="100%">
            <Grid container>
              <Grid item width="100%">
                <Grid container>
                  <Grid item>
                    <BodyText>
                      Used <InlineMonoText>{sgUsed}</InlineMonoText>
                    </BodyText>
                  </Grid>
                  <Grid item xs />
                  <Grid item textAlign="right">
                    <BodyText>
                      Free
                      <InlineMonoText>{sgFree}</InlineMonoText>/
                      <InlineMonoText>{sgSize}</InlineMonoText>
                    </BodyText>
                  </Grid>
                </Grid>
              </Grid>
              <Grid item width="100%">
                <StorageBar storageGroup={storageGroup} />
              </Grid>
            </Grid>
          </Grid>
          {...volumeGroups}
        </Grid>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export default StorageGroup;
