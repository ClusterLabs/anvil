import { date } from '../shell';

export const timestamp = () => {
  let result: string;

  try {
    result = date('--rfc-3339', 'ns').trim();
  } catch (error) {
    throw new Error(
      `Failed to get timestamp for database use; CAUSE: ${error}`,
    );
  }

  return result;
};
