import { Axios } from 'axios';

import API_BASE_URL from '../consts/API_BASE_URL';

const mainAxiosInstance = new Axios({
  baseURL: API_BASE_URL,
  validateStatus: (status) => status < 400,
});

export default mainAxiosInstance;
