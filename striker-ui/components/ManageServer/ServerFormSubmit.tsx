import { useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import Spinner from '../Spinner';
import useFetch from '../../hooks/useFetch';

const ServerFormSubmit: React.FC<ServerFormSubmitProps> = (props) => {
  const { dangerous, detail, formDisabled, label } = props;

  const { data: jobs } = useFetch<APIJobOverviewList>(
    `/job?name=${detail.uuid}::update`,
    {
      refreshInterval: 2000,
    },
  );

  const actionDisabled = useMemo<boolean>(() => {
    if (!jobs) {
      return true;
    }

    return formDisabled || Object.keys(jobs).length > 0;
  }, [formDisabled, jobs]);

  const background = useMemo(() => {
    if (dangerous) {
      return 'red';
    }

    return 'blue';
  }, [dangerous]);

  if (!jobs) {
    return <Spinner mt={0} />;
  }

  return (
    <ActionGroup
      actions={[
        {
          background,
          children: label,
          disabled: actionDisabled,
          type: 'submit',
        },
      ]}
    />
  );
};

export default ServerFormSubmit;
