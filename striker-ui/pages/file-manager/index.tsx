import Head from 'next/head';

import Files from '../../components/Files';
import Header from '../../components/Header';

const FileManager = (): JSX.Element => {
  return (
    <>
      <Head>
        <title>File Manager</title>
      </Head>
      <Header />
      <Files />
    </>
  );
};

export default FileManager;
