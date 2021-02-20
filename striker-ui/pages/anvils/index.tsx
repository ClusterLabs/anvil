import { GetServerSidePropsResult, InferGetServerSidePropsType } from 'next';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import Button from '../../components/atoms/Button';
import Header from '../../components/organisms/Header';
import List from '../../components/molecules/List';
import PageCenterContainer from '../../components/organisms/PageCenterContainer';
import PageContainer from '../../components/organisms/PageContainer';

import fetchJSON from '../../lib/fetchers/fetchJSON';

export async function getServerSideProps(): Promise<
  GetServerSidePropsResult<AnvilList>
> {
  return {
    props: await fetchJSON(`${API_BASE_URL}/api/anvils`),
  };
}

function DemoAnvilList({
  anvils,
}: InferGetServerSidePropsType<typeof getServerSideProps>): JSX.Element {
  return (
    <PageContainer>
      <Header />
      <PageCenterContainer>
        <List labelText="List of Anvils">
          {anvils.map(
            (anvil: AnvilListItem): JSX.Element => (
              <Button
                key={anvil.uuid}
                imageProps={{ src: '/pngs/anvil_icon_on.png' }}
                labelProps={{ text: anvil.uuid }}
                linkProps={{ href: `/anvils/${anvil.uuid}` }}
              />
            ),
          )}
        </List>
      </PageCenterContainer>
    </PageContainer>
  );
}

export default DemoAnvilList;
