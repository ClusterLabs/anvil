/**
 * Notes:
 * - Option `timeout` for child_process.spawn was added in node15.13.0 to limit
 *   the lifespan of the child process; this is **not** the max wait time before
 *   the child process starts successfully.
 */
type AccessStartOptions = {
  args?: readonly string[];
  restartInterval?: number;
} & import('child_process').SpawnOptions;

type SubroutineCommonParams = {
  debug?: number;
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
