type JobProgressListOptionalProps = {
  commands?: string[];
  names?: string[];
  uuids?: string[];
};

type JobProgressListProps = JobProgressListOptionalProps & {
  getLabel: (progress: number) => React.ReactNode;
  progress: {
    set: (value: number) => void;
    value: number;
  };
};
