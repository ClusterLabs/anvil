type AccessStartOptions = {
  args?: readonly string[];
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
