import http from 'k6/http';
import {sleep} from 'k6';

export const options = {
  stages: [
    { duration: '20s', target: 300 },
    { duration: '20s', target: 700 },
    { duration: '20s', target: 1000 },
    { duration: '30s', target: 3000 },
    { duration: '1m30s', target: 2000 },
    { duration: '5s', target: 1000 },
    { duration: '2m', target: 700 },
    { duration: '30s', target: 300 },
  ],
};

export default function () {
  const res = http.get('http://ASG-NLB-b4cfe072dc226dcf.elb.us-east-1.amazonaws.com');
  sleep(0.5);
}