import { FC, useState } from 'react';

import CrudList from '../CrudList';
import PrepareHostForm from './PrepareHostForm';
import TestAccessForm from './TestAccessForm';
import { BodyText } from '../Text';

const ManageHost: FC = () => {
  const [inquireHostResponse, setInquireHostResponse] = useState<
    InquireHostResponse | undefined
  >();

  return (
    <CrudList<APIHostOverview, APIHostDetail>
      addHeader="Initialize host"
      editHeader=""
      entriesUrl="/host"
      getDeleteErrorMessage={(children, ...rest) => ({
        ...rest,
        children: <>Failed to delete host(s). {children}</>,
      })}
      getDeleteHeader={(count) => `Delete the following ${count} host(s)?`}
      getDeleteSuccessMessage={() => ({
        children: <>Successfully deleted host(s)</>,
      })}
      listEmpty="No host(s) found"
      listProps={{ allowAddItem: true, allowEdit: false }}
      renderAddForm={(tools) => (
        <>
          <TestAccessForm setResponse={setInquireHostResponse} />
          {inquireHostResponse && (
            <PrepareHostForm host={inquireHostResponse} tools={tools} />
          )}
        </>
      )}
      renderDeleteItem={(hosts, { key }) => {
        const host = hosts?.[key];

        return <BodyText>{host?.shortHostName}</BodyText>;
      }}
      renderEditForm={() => <></>}
      renderListItem={(uuid, { hostName }) => <BodyText>{hostName}</BodyText>}
    />
  );
};

export default ManageHost;
