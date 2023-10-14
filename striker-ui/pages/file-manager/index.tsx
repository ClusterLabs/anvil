import Head from 'next/head';

import Header from '../../components/Header';
import ManageFilePanel from '../../components/Files/ManageFilePanel';

const FileManager = (): JSX.Element => (
  <>
    <Head>
      <title>File Manager</title>
    </Head>
    <Header />
    <ManageFilePanel />
  </>
);

export default FileManager;
