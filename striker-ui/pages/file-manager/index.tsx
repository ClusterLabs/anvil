import Head from 'next/head';

import Header from '../../components/Header';
import ManageFilePanel from '../../components/Files';

const FileManager = (): React.ReactElement => (
  <>
    <Head>
      <title>File Manager</title>
    </Head>
    <Header />
    <ManageFilePanel />
  </>
);

export default FileManager;
