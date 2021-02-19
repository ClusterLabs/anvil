import { NextPage } from 'next';
import useOneAnvil from '../lib/anvil/useOneAnvil';

const DemoAnvilStatus: NextPage = (): JSX.Element => {
  const {
    anvilStatus: { nodes, timestamp },
    error,
    isLoading,
  } = useOneAnvil(`d61c0383-5d82-4d9f-a193-b4a31cff1ceb`);

  return (
    <div>
      <h1>Demo Anvil Status</h1>
      <h2>nodes</h2>
      <pre>{JSON.stringify(nodes, null, 4)}</pre>
      <h2>timestamp</h2>
      <pre>{timestamp}</pre>
      <h2>isLoading</h2>
      <pre>{isLoading}</pre>
      <h2>error</h2>
      <pre>{error?.message}</pre>
    </div>
  );
};

export default DemoAnvilStatus;
