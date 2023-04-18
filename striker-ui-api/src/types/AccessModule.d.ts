type AsyncAnvilAccessModuleOptions = import('child_process').SpawnOptions & {
  onClose?: (args: {
    ecode: number | null;
    signal: NodeJS.Signals | null;
    stderr: string;
    stdout: unknown;
  }) => void;
  onError?: (err: Error) => void;
};
