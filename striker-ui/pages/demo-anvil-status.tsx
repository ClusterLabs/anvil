import { GetServerSidePropsResult, InferGetServerSidePropsType } from 'next';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import fetchJSON from '../lib/fetchers/fetchJSON';

export async function getServerSideProps(): Promise<
  GetServerSidePropsResult<AnvilStatus>
> {
  return {
    props: await fetchJSON(
      `${API_BASE_URL}/api/anvils/1aded871-fcb1-4473-9b97-6e9c246fc568`,
    ),
  };
}

function DemoAnvilStatus({
  nodes,
  timestamp,
}: InferGetServerSidePropsType<typeof getServerSideProps>): JSX.Element {
  return (
    <div>
      <h1>Demo Anvil List</h1>
      <h2>nodes</h2>
      <pre>{JSON.stringify(nodes, null, 4)}</pre>
      <h2>timestamp</h2>
      <pre>{timestamp}</pre>
    </div>
  );
}

export default DemoAnvilStatus;
