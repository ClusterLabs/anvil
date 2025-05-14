import { FC, ReactNode, useMemo } from 'react';

import AnvilSummary from './AnvilSummary';
import { toAnvilOverviewList } from '../../lib/api_converters';
import Grid from '../Grid';
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
import { BodyText, HeaderText } from '../Text';
import useFetch from '../../hooks/useFetch';

const AnvilSummaryList: FC<AnvilSummaryListProps> = (props) => {
  const { refreshInterval = 5000 } = props;

  const {
    altData: anvils,
    loading,
    validating,
  } = useFetch<APIAnvilOverviewArray, APIAnvilOverviewList>('/anvil', {
    mod: toAnvilOverviewList,
    refreshInterval,
  });

  const grid = useMemo<ReactNode>(
    () =>
      anvils && (
        <Grid
          alignContent="stretch"
          layout={Object.values(anvils).reduce<GridLayout>(
            (previous, current) => {
              const { description, name, uuid } = current;

              const key = `anvil-${uuid}`;

              previous[key] = {
                children: (
                  <InnerPanel mv={0}>
                    <InnerPanelHeader>
                      <Link href={`/anvil?name=${name}`} noWrap>
                        {name}
                      </Link>
                      <BodyText
                        overflow="hidden"
                        textOverflow="ellipsis"
                        whiteSpace="nowrap"
                      >
                        {description}
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
                maxWidth: {
                  xs: '100%',
                  md: '50%',
                  lg: 'calc(100% / 3)',
                  xl: '25%',
                },
                minWidth: '24em',
                xs: true,
              };

              return previous;
            },
            {},
          )}
          spacing="1em"
        />
      ),
    [anvils, refreshInterval],
  );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText>Nodes</HeaderText>
        <SyncIndicator syncing={validating} />
      </PanelHeader>
      {loading ? <Spinner /> : grid}
    </Panel>
  );
};

export default AnvilSummaryList;
