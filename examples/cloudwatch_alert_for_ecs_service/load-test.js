import http from "k6/http";
import { check, sleep } from "k6";

export let options = {
    insecureSkipTLSVerify: true,
    noConnectionReuse: false,
    vus: 100,
    duration: '300s'
};

// Simulated user behavior
export default function () {
  let res = http.get("https://d3hq0mud96hr6l.cloudfront.net/api/");
  // Validate response status
  check(res, { "status was 200": (r) => r.status == 200 });
}
