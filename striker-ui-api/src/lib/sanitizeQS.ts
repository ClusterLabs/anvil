import call from './call';
import { sanitizeSQLParam } from './sanitizeSQLParam';

type MapToReturnType = {
  boolean: boolean;
  number: number;
  string: string;
  'string[]': string[];
};

type MapToReturnFunction = {
  [ReturnTypeName in keyof MapToReturnType]: (
    qs: unknown,
    modifier: (value: unknown) => string,
  ) => MapToReturnType[ReturnTypeName];
};

type ModifierFunction = (value: string) => string;

type MapToModifierFunction = {
  none: undefined;
  sql: ModifierFunction;
};

const MAP_TO_MODIFIER_FUNCTION: MapToModifierFunction = {
  none: undefined,
  sql: sanitizeSQLParam,
};

const MAP_TO_RETURN_FUNCTION: MapToReturnFunction = {
  boolean: (qs) => qs !== undefined,
  number: (qs) => parseFloat(String(qs)) || 0,
  string: (qs, mod) => (qs ? mod(qs) : ''),
  'string[]': (qs, mod) => {
    let result: string[] = [];

    if (qs instanceof Array) {
      result = qs.reduce<string[]>((reduceContainer, element) => {
        if (element) {
          reduceContainer.push(mod(element));
        }

        return reduceContainer;
      }, []);
    } else if (qs) {
      result = mod(qs).split(/[,;]/);
    }

    return result;
  },
};

export const sanitizeQS = <ReturnTypeName extends keyof MapToReturnType>(
  qs: unknown,
  {
    modifierType = 'none',
    modifier = MAP_TO_MODIFIER_FUNCTION[modifierType],
    returnType = 'string',
  }: {
    modifier?: ModifierFunction;
    modifierType?: keyof MapToModifierFunction;
    returnType?: ReturnTypeName | 'string';
  } = {},
): MapToReturnType[ReturnTypeName] =>
  MAP_TO_RETURN_FUNCTION[returnType](qs, (value: unknown) => {
    const input = String(value);

    return call<string>(modifier, {
      notCallableReturn: input,
      parameters: [input],
    });
  }) as MapToReturnType[ReturnTypeName];
