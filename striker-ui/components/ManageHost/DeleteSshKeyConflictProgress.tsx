import { useMemo } from 'react';

import JobProgressList from '../JobProgressList';

const DeleteSshKeyConflictProgress: React.FC<
  DeleteSshKeyConflictProgressProps
> = (props) => {
  const { jobs: ids, progress: jobProgress } = props;

  // Only look at progress of the job targeting the local striker
  const scope = useMemo(
    () => Object.keys(ids).filter((key) => ids[key].local),
    [ids],
  );

  return (
    <JobProgressList
      getLabel={(progress) =>
        progress === 100 ? 'Finished deletion.' : 'Deleting...'
      }
      progress={{
        set: jobProgress.setTotal,
        value: jobProgress.total,
      }}
      uuids={scope}
    />
  );
};

export default DeleteSshKeyConflictProgress;
