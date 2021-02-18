import { GetServerSidePropsResult, InferGetServerSidePropsType } from 'next';
import styled from 'styled-components';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import DEFAULT_THEME from '../lib/consts/DEFAULT_THEME';

import Label from '../components/atoms/Label';
import List from '../components/molecules/List';

import fetchJSON from '../lib/fetchers/fetchJSON';

export async function getServerSideProps(): Promise<
  GetServerSidePropsResult<AnvilList>
> {
  return {
    props: await fetchJSON(`${API_BASE_URL}/api/anvils`),
  };
}

const StyledPageContainer = styled.div`
  min-height: 100vh;
  width: 100vw;

  background-color: ${(props) => props.theme.colors.secondary};
`;

StyledPageContainer.defaultProps = {
  theme: DEFAULT_THEME,
};

function DemoAnvilList({
  anvils,
}: InferGetServerSidePropsType<typeof getServerSideProps>): JSX.Element {
  return (
    <StyledPageContainer>
      <Label text="anvils" />
      <List>
        {anvils.map(
          (anvil: AnvilListItem): JSX.Element => (
            <Label key={anvil.uuid} text={anvil.uuid} />
          ),
        )}
      </List>
    </StyledPageContainer>
  );
}

export default DemoAnvilList;
