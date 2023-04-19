type AsyncAnvilAccessModuleCloseArgs = {
  ecode: number | null;
  signal: NodeJS.Signals | null;
  stderr: string;
  stdout: unknown;
};

type AsyncDatabaseWriteCloseArgs = AsyncAnvilAccessModuleCloseArgs & {
  wcode: number | null;
};

type AsyncAnvilAccessModuleCloseHandler = (
  args: AsyncAnvilAccessModuleCloseArgs,
) => void;

type AsyncDatabaseWriteCloseHandler = (
  args: AsyncDatabaseWriteCloseArgs,
) => void;

type AsyncAnvilAccessModuleOptions = import('child_process').SpawnOptions & {
  onClose?: AsyncAnvilAccessModuleCloseHandler;
  onError?: (err: Error) => void;
};

type AsyncDatabaseWriteOptions = Omit<
  AsyncAnvilAccessModuleOptions,
  'onClose'
> & {
  onClose?: AsyncDatabaseWriteCloseHandler;
};
