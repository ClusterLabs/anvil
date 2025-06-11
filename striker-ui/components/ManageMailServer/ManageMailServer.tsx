import AddMailServerForm from './AddMailServerForm';
import CrudList from '../CrudList';
import EditMailServerForm from './EditMailServerForm';
import { BodyText } from '../Text';
import useFetch from '../../hooks/useFetch';

const ManageMailServer: React.FC = () => {
  const { data: host, loading: loadingHost } =
    useFetch<APIHostDetail>('/host/local');

  return (
    <CrudList<APIMailServerOverview, APIMailServerDetail>
      addHeader="Add mail server"
      editHeader={(entry) => `Update ${entry?.address}:${entry?.port}`}
      entriesUrl="/mail-server"
      getAddLoading={(previous) => previous || loadingHost}
      getDeleteErrorMessage={({ children, ...rest }) => ({
        ...rest,
        children: <>Failed to delete mail server(s). {children}</>,
      })}
      getDeleteHeader={(count) =>
        `Delete the following ${count} mail server(s)?`
      }
      getDeleteSuccessMessage={() => ({
        children: <>Successfully deleted mail server(s).</>,
      })}
      listEmpty="No mail server(s) found"
      renderAddForm={(tools) =>
        host && (
          <AddMailServerForm
            localhostDomain={host.variables.domain}
            tools={tools}
          />
        )
      }
      renderDeleteItem={(mailServers, { key }) => {
        const ms = mailServers?.[key];

        return (
          <BodyText>
            {ms?.address}:{ms?.port}
          </BodyText>
        );
      }}
      renderEditForm={(tools, mailServer) =>
        mailServer && (
          <EditMailServerForm
            mailServerUuid={mailServer.uuid}
            previousFormikValues={{ [mailServer.uuid]: mailServer }}
            tools={tools}
          />
        )
      }
      renderListItem={(uuid, { address, port }) => (
        <BodyText>
          {address}:{port}
        </BodyText>
      )}
    />
  );
};

export default ManageMailServer;
