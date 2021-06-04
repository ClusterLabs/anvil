const putJSON = <T>(uri: string, data: T): void => {
  fetch(`${process.env.NEXT_PUBLIC_API_URL}${uri}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });
};

export default putJSON;
