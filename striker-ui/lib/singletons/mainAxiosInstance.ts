import { Axios } from 'axios';

const mainAxiosInstance = new Axios({
  baseURL: process.env.NEXT_PUBLIC_API_URL?.replace('/cgi-bin', '/api'),
});

export default mainAxiosInstance;
