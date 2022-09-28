type MapToReturnType = {
  boolean: boolean;
  number: number;
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
  number: (qs) => (Number.isFinite(qs) ? parseFloat(String(qs)) : 0),
  string: (qs) => (qs ? String(qs) : ''),
  'string[]': (qs) => {
    let result: string[] = [];

    if (qs instanceof Array) {
      result = qs.reduce<string[]>((reduceContainer, element) => {
        if (element) {
          reduceContainer.push(String(element));
        }

        return reduceContainer;
      }, []);
    } else if (qs) {
      result = String(qs).split(/[,;]/);
    }

    return result;
  },
};

export const sanitizeQS = <ReturnTypeName extends keyof MapToReturnType>(
  qs: unknown,
  { returnType = 'string' }: { returnType?: ReturnTypeName | 'string' } = {},
): MapToReturnType[ReturnTypeName] =>
  MAP_TO_RETURN_FUNCTION[returnType](qs) as MapToReturnType[ReturnTypeName];
