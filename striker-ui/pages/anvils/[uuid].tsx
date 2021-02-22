import { NextPage } from 'next';
import styled from 'styled-components';
import { useRouter } from 'next/dist/client/router';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

import ExtendedDate from '../../lib/extended_date/ExtendedDate';
import Header from '../../components/organisms/Header';
import Label from '../../components/atoms/Label';
import List from '../../components/molecules/List';
import PageCenterContainer from '../../components/organisms/PageCenterContainer';
import PageContainer from '../../components/organisms/PageContainer';
import ToggleSwitch from '../../components/atoms/ToggleSwitch';

import useOneAnvil from '../../lib/anvil/useOneAnvil';

const StyledAnvilNodeStatus = styled.div`
  display: flex;

  flex-direction: column;

  width: 100%;
  height: 100%;
`;

const StyledAnvilNodePower = styled.div`
  display: flex;

  flex-direction: row;

  justify-content: space-around;

  width: 100%;

  margin-top: 1em;
`;

StyledAnvilNodeStatus.defaultProps = {
  theme: DEFAULT_THEME,
};

StyledAnvilNodePower.defaultProps = {
  theme: DEFAULT_THEME,
};

const DemoAnvilStatus: NextPage = (): JSX.Element => {
  const router = useRouter();
  const { uuid } = router.query;
  const anvilUUID: string = uuid instanceof Array ? uuid[0] : uuid ?? '';
  const {
    anvilStatus: { nodes, timestamp },
    error,
    isLoading,
  } = useOneAnvil(anvilUUID);

  const lastUpdatedDatetime: string = new ExtendedDate(
    timestamp * 1000,
  ).toLocaleISOString();

  return (
    <PageContainer>
      <Header />
      <PageCenterContainer>
        <List labelText="Anvil Status" isAlignHorizontal>
          {(() => {
            let resultElement: JSX.Element[];

            if (isLoading) {
              resultElement = [
                <Label key="loading" text="Loading Anvil status..." />,
              ];
            } else if (error !== null) {
              resultElement = [
                <Label
                  key="error"
                  text={`Failed to get Anvil status; CAUSE: ${error}`}
                />,
              ];
            } else {
              resultElement = nodes.map(
                ({ on }: AnvilNodeStatus, nodeIndex: number) => {
                  const nodeName = `Node ${nodeIndex + 1}`;

                  return (
                    <StyledAnvilNodeStatus key={nodeName}>
                      <Label text={nodeName} />
                      <StyledAnvilNodePower>
                        <Label text="Power" />
                        <ToggleSwitch checked={on === 1} />
                      </StyledAnvilNodePower>
                    </StyledAnvilNodeStatus>
                  );
                },
              );
            }

            return resultElement;
          })()}
        </List>
        <List labelText="Last Updated">
          <Label text={lastUpdatedDatetime} />
        </List>
      </PageCenterContainer>
    </PageContainer>
  );
};

export default DemoAnvilStatus;
