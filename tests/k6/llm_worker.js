import http from "k6/http";

import { sleep, check } from "k6";

// Current liveview session from browser
const cookie = "SFMyNTY.g3QAAAABbQAAAAtfY3NyZl90b2tlbm0AAAAYUDlEM2tYd0V1SmxxTTlKS21IWVZaNDhz.1oNOlP8K0lcNs6TtiLHw5EI2C1YOrtsWTTRAqfQyS9M";

export default function () {
  let res = http.get("http://85.209.9.165/134556694", {
    // dont follow authentication failure redirects
    // redirects: 0,
    cookies: {
      _dotanicks_web_key: cookie,
    }
  });

	// Если статус не равен 200 – выводим его в лог
  if (res.status !== 200) {
    console.log(`Ответ с кодом ${res.status}: ${res.body}`);
  }

	check(res, {
		"status 200": (r) => r.status === 200,
		"contains header": (r) => r.body.includes("История ников"),
	});

  sleep(1);
}
