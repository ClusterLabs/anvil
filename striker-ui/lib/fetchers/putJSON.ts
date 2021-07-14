/* eslint-disable @typescript-eslint/no-explicit-any */
const putJSON = <T>(uri: string, data: T): Promise<any> => {
  return fetch(uri, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });
};

export default putJSON;
