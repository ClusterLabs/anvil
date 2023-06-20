type AccessStartOptions = {
  args?: readonly string[];
} & import('child_process').SpawnOptions;

type SubroutineCommonParams = {
  debug?: number;
};

type InsertOrUpdateFunctionCommonParams = SubroutineCommonParams & {
  file: string;
  line?: number;
};
