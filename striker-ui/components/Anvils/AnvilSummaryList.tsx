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

const AnvilSummaryList: FC = () => {
  const { data: rawAnvils, loading: loadingAnvils } =
    useFetch<APIAnvilOverviewArray>('/anvil', { refreshInterval: 5000 });

  const anvils = useMemo<APIAnvilOverviewList | undefined>(
    () => rawAnvils && toAnvilOverviewList(rawAnvils),
    [rawAnvils],
  );

  const grid = useMemo<ReactNode>(
    () =>
      anvils && (
        <Grid
          columns={{ xs: 1, sm: 2, md: 3, lg: 4, xl: 5 }}
          layout={Object.values(anvils).reduce<GridLayout>(
            (previous, current) => {
              const { description, name, uuid } = current;

              const key = `anvil-${uuid}`;

              previous[key] = {
                children: (
                  <InnerPanel>
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
                      <AnvilSummary anvilUuid={uuid} />
                    </InnerPanelBody>
                  </InnerPanel>
                ),
              };

              return previous;
            },
            {},
          )}
        />
      ),
    [anvils],
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
