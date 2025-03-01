import { useMemo } from 'react';

const useJobStatus = (
  list?: Record<string, APIJobStatus>,
): {
  lines: string[];
  string: string;
} => {
  const lines = useMemo<string[]>(() => {
    if (!list) {
      return [];
    }

    const entries = Object.entries(list);

    return entries.map<string>((entry) => {
      const [, { value }] = entry;

      return value;
    });
  }, [list]);

  const string = useMemo<string>(() => lines.join('\n'), [lines]);

  return {
    lines,
    string,
  };
};

export default useJobStatus;
