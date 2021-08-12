/* eslint-disable @typescript-eslint/no-explicit-any */
const putFetchTimeout = async <T>(
  uri: string,
  data: T,
  timeout: number,
): Promise<any> => {
  const controller = new AbortController();

  const id = setTimeout(() => controller.abort(), timeout);

  const res = await fetch(uri, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Keep-Alive': 'timeout=120',
    },
    signal: controller.signal,
    body: JSON.stringify(data),
  });
  clearTimeout(id);

  return res;
};

export default putFetchTimeout;
