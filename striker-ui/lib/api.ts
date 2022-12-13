import axios, { Axios } from 'axios';

import API_BASE_URL from './consts/API_BASE_URL';

const api = new Axios({
  baseURL: API_BASE_URL,
  transformRequest: axios.defaults.transformRequest,
  transformResponse: axios.defaults.transformResponse,
  validateStatus: (status) => status < 400,
});

export default api;
