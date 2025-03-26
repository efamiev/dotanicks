import http from "k6/http";

import { sleep, check } from "k6";

// Current liveview session from browser
const cookie = "SFMyNTY.g3QAAAADbQAAAAtfY3NyZl90b2tlbm0AAAAYMC04MFU0NER0Wm1aYXFDM0J1ZlFFOG5abQAAAA5saXZlX3NvY2tldF9pZG0AAAA7dXNlcnNfc2Vzc2lvbnM6S1RtX0J0WDZ4bTMwckJfLVM4T1VHQjVIUC1JQVpLN1BBdERTd2U3V1hWST1tAAAACnVzZXJfdG9rZW5tAAAAICk5vwbV-sZt9Kwf_kvDlBgeRz_iAGSuzwLQ0sHu1l1S.b-2oNDR0WPBhknmXehJsWtLLt2Cwf3KNgSQ3czfhp0A";

export default function () {
  let res = http.get("http://85.209.9.165/life_complexities", {
    // dont follow authentication failure redirects
    // redirects: 0,
    cookies: {
      _life_complex_key: cookie,
    }
  });

	// Если статус не равен 200 – выводим его в лог
  if (res.status !== 200) {
    console.log(`Ответ с кодом ${res.status}: ${res.body}`);
  }

	check(res, {
		"status 200": (r) => r.status === 200,
		"contains header": (r) => r.body.includes("Listing Life complexities"),
	});

  sleep(1);
}
