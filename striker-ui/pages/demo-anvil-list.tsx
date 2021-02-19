import { GetServerSidePropsResult, InferGetServerSidePropsType } from 'next';
import styled from 'styled-components';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import DEFAULT_THEME from '../lib/consts/DEFAULT_THEME';

import Button from '../components/atoms/Button';
import Header from '../components/organisms/Header';
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

const StyledCenterContainer = styled.div`
  width: 50%;

  padding-top: 1em;

  margin-left: auto;
  margin-right: auto;
`;

StyledPageContainer.defaultProps = {
  theme: DEFAULT_THEME,
};

StyledCenterContainer.defaultProps = {
  theme: DEFAULT_THEME,
};

function DemoAnvilList({
  anvils,
}: InferGetServerSidePropsType<typeof getServerSideProps>): JSX.Element {
  return (
    <StyledPageContainer>
      <Header />
      <StyledCenterContainer>
        <List labelText="List of Anvils">
          {anvils.map(
            (anvil: AnvilListItem): JSX.Element => (
              <Button
                key={anvil.uuid}
                imageProps={{ src: '/pngs/anvil_icon_on.png' }}
                labelProps={{ text: anvil.uuid }}
                linkProps={{ href: '/demo-anvil-status' }}
              />
            ),
          )}
        </List>
      </StyledCenterContainer>
    </StyledPageContainer>
  );
}

export default DemoAnvilList;
