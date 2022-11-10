type DBInsertOrUpdateFunctionCommonParams = {
  debug?: number;
  file: string;
  line?: number;
};

type DBInsertOrUpdateFunctionCommonOptions = Omit<
  ExecModuleSubroutineOptions,
  'subParams' | 'subModuleName'
>;
