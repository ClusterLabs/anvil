import { Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useMemo } from 'react';

import { StorageBar } from '../Bars';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import { BodyText, InlineMonoText } from '../Text';

const StorageGroup: React.FC<StorageGroupProps> = (props) => {
  const { storageGroup } = props;

  const { members, name } = storageGroup;

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
                      Used: <InlineMonoText>{sgUsed}</InlineMonoText>
                    </BodyText>
                  </Grid>
                  <Grid item xs />
                  <Grid item textAlign="right">
                    <BodyText>
                      Free: <InlineMonoText>{sgFree}</InlineMonoText>
                    </BodyText>
                  </Grid>
                </Grid>
              </Grid>
              <Grid item width="100%">
                <StorageBar storageGroup={storageGroup} />
              </Grid>
              <Grid item width="100%">
                <BodyText>
                  Total: <InlineMonoText>{sgSize}</InlineMonoText>
                </BodyText>
              </Grid>
            </Grid>
          </Grid>
          {Object.values(members).map((member) => {
            const { volumeGroup } = member;

            const vgFree =
              dSizeStr(volumeGroup.free, { toUnit: 'ibyte' }) ?? 'none';

            const vgSize =
              dSizeStr(volumeGroup.size, { toUnit: 'ibyte' }) ?? 'none';

            return (
              <Grid item key={member.uuid} width="100%">
                <Grid container>
                  <Grid item width="100%">
                    <BodyText>{volumeGroup.name}</BodyText>
                  </Grid>
                  <Grid item xs>
                    <BodyText variant="caption">
                      {volumeGroup.host.short}
                    </BodyText>
                  </Grid>
                  <Grid item xs>
                    <BodyText mb="-.3em" variant="caption">
                      Free
                      <InlineMonoText>{vgFree}</InlineMonoText>/
                      <InlineMonoText>{vgSize}</InlineMonoText>
                    </BodyText>
                  </Grid>
                  <Grid item width="100%">
                    <StorageBar volumeGroup={volumeGroup} />
                  </Grid>
                </Grid>
              </Grid>
            );
          })}
        </Grid>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export default StorageGroup;
