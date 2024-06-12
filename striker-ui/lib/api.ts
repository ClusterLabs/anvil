import axios from 'axios';

import API_BASE_URL from './consts/API_BASE_URL';

const api = axios.create({
  baseURL: API_BASE_URL,
  transformRequest: axios.defaults.transformRequest,
  transformResponse: axios.defaults.transformResponse,
  validateStatus: (status) => status < 400,
  withCredentials: true,
});

export default api;
