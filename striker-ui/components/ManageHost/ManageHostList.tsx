import { useState } from 'react';

import CrudList from '../CrudList';
import { DialogScrollBox } from '../Dialog';
import FormSummary from '../FormSummary';
import HostListItem from './HostListItem';
import IconButton from '../IconButton';
import PrepareHostForm from './PrepareHostForm';
import TestAccessForm from './TestAccessForm';
import { BodyText } from '../Text';

const ManageHostList: React.FC<ManageHostListProps> = (props) => {
  const { onValidateHostsChange } = props;

  const [inquireHostResponse, setInquireHostResponse] = useState<
    InquireHostResponse | undefined
  >();

  return (
    <CrudList<APIHostOverview, APIHostDetail>
      formDialogProps={{
        common: {
          onClose: ({ handlers: { base } }, ...args) => {
            base?.call(null, ...args);
            // Delay to avoid visual changes until dialog is fully closed.
            setTimeout(setInquireHostResponse, 500);
          },
        },
      }}
      addHeader="Initialize host"
      editHeader=""
      entriesUrl="/host?type=dr&type=subnode"
      entryUrlPrefix="/host"
      getDeleteErrorMessage={(children, ...rest) => ({
        ...rest,
        children: <>Failed to delete host(s). {children}</>,
      })}
      getDeleteHeader={(count) => `Delete the following ${count} host(s)?`}
      getDeleteSuccessMessage={() => ({
        children: <>Successfully deleted host(s)</>,
      })}
      listEmpty="No host(s) found."
      listProps={{
        allowAddItem: true,
        allowEdit: false,
        // There's no edit mode for host list right now, use the edit dialog to
        // display the details of a host.
        allowItemButton: true,
      }}
      onValidateEntriesChange={onValidateHostsChange}
      renderAddForm={(tools) => (
        <>
          <TestAccessForm setResponse={setInquireHostResponse} tools={tools} />
          {inquireHostResponse && (
            <PrepareHostForm
              host={inquireHostResponse}
              setResponse={setInquireHostResponse}
              tools={tools}
            />
          )}
        </>
      )}
      renderDeleteItem={(hosts, { key }) => {
        const host = hosts?.[key];

        return <BodyText>{host?.shortHostName}</BodyText>;
      }}
      renderEditForm={(tools, detail) =>
        detail && (
          <DialogScrollBox>
            <FormSummary
              entries={detail}
              renderEntryValue={(base, ...args) => {
                const {
                  0: { entry, key },
                } = args;

                if (key === 'command')
                  return (
                    <IconButton
                      iconProps={{ fontSize: 'small' }}
                      mapPreset="copy"
                      onClick={() =>
                        navigator.clipboard.writeText(String(entry))
                      }
                      size="small"
                    />
                  );

                return base(...args);
              }}
              hasPassword
            />
          </DialogScrollBox>
        )
      }
      renderListItem={(uuid, host) => <HostListItem data={host} />}
    />
  );
};

export default ManageHostList;
