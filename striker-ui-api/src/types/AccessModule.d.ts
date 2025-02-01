/**
 * Notes:
 * - Option `timeout` for child_process.spawn was added in node15.13.0 to limit
 *   the lifespan of the child process; this is **not** the max wait time before
 *   the child process starts successfully.
 */
type AccessStartOptions = {
  args?: readonly string[];
  restartInterval?: number;
  spawn?: import('child_process').SpawnOptions;
};

type AccessOptions = {
  emitter?: ConstructorParameters<typeof import('events').EventEmitter>[0];
  start?: AccessStartOptions;
};

type SubroutineCommonParams = {
  debug?: number;
};

type SubroutineOutputWrapper<T extends unknown[]> = {
  sub_results: T;
};

/**
 * @prop file - Source file name
 * @prop line - Source file line number
 * @prop uuid - Database UUID
 */
type InsertOrUpdateFunctionCommonParams = SubroutineCommonParams & {
  file: string;
  line?: number;
  uuid?: string;
};
