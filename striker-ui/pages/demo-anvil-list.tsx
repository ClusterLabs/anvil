import { GetServerSidePropsResult, InferGetServerSidePropsType } from 'next';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import fetchJSON from '../lib/fetchers/fetchJSON';

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
    <div>
      <h1>Demo Anvil List</h1>
      <h2>anvils</h2>
      <pre>{JSON.stringify(anvils, null, 4)}</pre>
    </div>
  );
}

export default DemoAnvilList;
