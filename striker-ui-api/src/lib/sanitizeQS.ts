type MapToReturnType = {
  boolean: boolean;
  string: string;
  'string[]': string[];
};

type MapToReturnFunction = {
  [ReturnTypeName in keyof MapToReturnType]: (
    qs: unknown,
  ) => MapToReturnType[ReturnTypeName];
};

const MAP_TO_RETURN_FUNCTION: MapToReturnFunction = {
  boolean: (qs) => qs !== undefined,
  string: (qs) => String(qs),
  'string[]': (qs) =>
    qs instanceof Array
      ? qs.map((element) => String(element))
      : String(qs).split(/[,;]/),
};

export const sanitizeQS = <ReturnTypeName extends keyof MapToReturnType>(
  qs: unknown,
  { returnType = 'string' }: { returnType?: ReturnTypeName | 'string' } = {},
): MapToReturnType[ReturnTypeName] =>
  MAP_TO_RETURN_FUNCTION[returnType](qs) as MapToReturnType[ReturnTypeName];
