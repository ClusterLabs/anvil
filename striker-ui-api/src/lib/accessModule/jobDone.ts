import join from '../join';
import { query } from './query';

export const jobDone = (
  uuids: string[],
  {
    attempts = 60,
    interval = 1000,
  }: {
    attempts?: number;
    interval?: number;
  } = {},
): Promise<void> =>
  new Promise<void>((resolve) => {
    if (!uuids.length) {
      throw new Error('No jobs');
    }

    const uuidsCsv = join(uuids, {
      elementWrapper: "'",
      separator: ', ',
    });

    const sql = `
      SELECT
        FLOOR(
          AVG(job_progress)
        ) AS total_progress
      FROM jobs
      WHERE job_uuid IN (${uuidsCsv})`;

    let count = 0;

    const id = setInterval(async () => {
      count += 1;

      if (count > attempts) {
        clearInterval(id);

        throw new Error('Timeout');
      }

      let rows: string[][];

      try {
        rows = await query(sql);
      } catch (error) {
        clearInterval(id);

        throw error;
      }

      if (!rows.length) {
        return;
      }

      const [row] = rows;

      const progress = Number(row[0]);

      if (progress !== 100) {
        return;
      }

      clearInterval(id);
      resolve();
    }, interval);
  });
