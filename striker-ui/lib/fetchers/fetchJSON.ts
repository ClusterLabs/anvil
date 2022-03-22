const fetchJSON = <T>(...args: [RequestInfo, RequestInit?]): Promise<T> =>
  fetch(...args).then((response: Response) => response.json());

export default fetchJSON;
