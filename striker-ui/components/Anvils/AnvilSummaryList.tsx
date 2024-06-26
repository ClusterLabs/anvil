import { gridClasses } from '@mui/material';
import { FC, ReactNode, useMemo } from 'react';

import AnvilSummary from './AnvilSummary';
import { toAnvilOverviewList } from '../../lib/api_converters';
import Grid from '../Grid';
import {
  InnerPanel,
  InnerPanelBody,
  InnerPanelHeader,
  Panel,
  PanelHeader,
} from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import useFetch from '../../hooks/useFetch';

const AnvilSummaryList: FC<AnvilSummaryListProps> = (props) => {
  const { refreshInterval = 5000 } = props;

  const { data: rawAnvils, loading: loadingAnvils } =
    useFetch<APIAnvilOverviewArray>('/anvil', { refreshInterval });

  const anvils = useMemo<APIAnvilOverviewList | undefined>(
    () => rawAnvils && toAnvilOverviewList(rawAnvils),
    [rawAnvils],
  );

  const grid = useMemo<ReactNode>(
    () =>
      anvils && (
        <Grid
          columns={{ xs: 1, sm: 2, md: 3, xl: 4 }}
          layout={Object.values(anvils).reduce<GridLayout>(
            (previous, current) => {
              const { description, name, uuid } = current;

              const key = `anvil-${uuid}`;

              previous[key] = {
                children: (
                  <InnerPanel height="100%" mv={0}>
                    <InnerPanelHeader>
                      <BodyText
                        overflow="hidden"
                        textOverflow="ellipsis"
                        whiteSpace="nowrap"
                      >
                        {name}: {description}
                      </BodyText>
                    </InnerPanelHeader>
                    <InnerPanelBody>
                      <AnvilSummary
                        anvilUuid={uuid}
                        refreshInterval={refreshInterval}
                      />
                    </InnerPanelBody>
                  </InnerPanel>
                ),
              };

              return previous;
            },
            {},
          )}
          spacing="1em"
          sx={{
            alignContent: 'stretch',

            [`& > .${gridClasses.item}`]: {
              minWidth: '20em',
            },
          }}
        />
      ),
    [anvils, refreshInterval],
  );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText>Nodes</HeaderText>
      </PanelHeader>
      {loadingAnvils ? <Spinner /> : grid}
    </Panel>
  );
};

export default AnvilSummaryList;
