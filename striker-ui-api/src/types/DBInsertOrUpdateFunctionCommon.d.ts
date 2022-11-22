type DBInsertOrUpdateFunctionCommonParams = ModuleSubroutineCommonParams & {
  file: string;
  line?: number;
};

type DBInsertOrUpdateFunctionCommonOptions = Omit<
  ExecModuleSubroutineOptions,
  'subParams' | 'subModuleName'
>;
