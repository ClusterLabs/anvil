import { perr } from '../shell';
import { sub } from './sub';

export const translate = async (value: string): Promise<string> => {
  let result = '';

  try {
    [result] = await sub<[string]>('parse_banged_string', {
      params: [{ key_string: value }],
      pre: ['Words'],
    });
  } catch (error) {
    // Log the error and fallback to empty string.
    perr(`Failed to translate; CAUSE: ${error}`);
  }

  return result;
};
