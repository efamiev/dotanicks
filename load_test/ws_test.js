import http from "k6/http";
import { sleep, check, fail } from "k6";
import ws from "k6/ws";

const cookie = "SFMyNTY.g3QAAAADbQAAAAtfY3NyZl90b2tlbm0AAAAYdFdWelFmZFFIaENzVmxrWGFrOTE3STh2bQAAAA5saXZlX3NvY2tldF9pZG0AAAA7dXNlcnNfc2Vzc2lvbnM6S1RtX0J0WDZ4bTMwckJfLVM4T1VHQjVIUC1JQVpLN1BBdERTd2U3V1hWST1tAAAACnVzZXJfdG9rZW5tAAAAICk5vwbV-sZt9Kwf_kvDlBgeRz_iAGSuzwLQ0sHu1l1S.EdO2i2mfreKWtUp9ZaZwuoU8Z57yr7qbwzqTrO28FB8";

export let options = {
  stages: [
    { duration: '30s', target: 10 }, // 0 -> 10 VUs
    { duration: '1m',  target: 10 }, // держим 10 VUs
    { duration: '30s', target: 20 }, // 10 -> 20 VUs
    { duration: '1m',  target: 20 }, // держим 20 VUs
    { duration: '30s', target: 0 },  // 20 -> 0 VUs
  ],
};

export default function () {
  const host = "85.209.9.165";
  // const host = "localhost:8080";
  const origin = `http://${host}`;
  const wsProtocol = "ws";
  const options = {
    redirects: 0,
    cookies: {
      _life_complex_key: cookie,
    },
  };

  let url = `http://${host}/life_complexities`;
  let res = http.get(url, options);

  check(res, {
    "status 200": (r) => r.status === 200,
    "contains header": (r) => r.body.includes("Listing Life complexities"),
  });

  checkLiveViewUpgrade(host, origin, wsProtocol, cookie, res, url, {debug: true});

  sleep(1);
  //
  // url = `http://${host}/glennr`;
  // res = http.get(url, options);
  //
  // check(res, {
  //   "songs status 200": (r) => r.status === 200,
  //   "contains table": (r) => r.body.includes("Artist"),
  // });
  //
  // checkLiveViewUpgrade(host, origin, wsProtocol, cookie, res, url);
  //
  // sleep(1);
}


// Connects the websocket to ensure the LV is upgraded.
//
// - parse the response HTML to find the LiveView websocket connection information (csrf token, topic etc)
// - build a `phx_join` message payload
// - issue a ws.connect()
//  - including several callback handlers
// - when a socket message was received, we assume the view was upgraded, and the websocket is closed.
function checkLiveViewUpgrade(
  host,
  testHost,
  wsProto,
  cookie,
  response,
  url,
  opts = {}
) {
  const debug = opts.debug || false;
  // The response html contains the LV websocket connection details
  const props = grabLVProps(response);
  const wsCsrfToken = props.wsCsrfToken;
  const phxSession = props.phxSession;
  const phxStatic = props.phxStatic;
  const topic = `lv:${props.phxId}`;
  const ws_url = `${wsProto}://${host}/live/websocket?vsn=2.0.0&_csrf_token=${wsCsrfToken}`;

  if (debug) console.log(`connecting ${ws_url}`);

  // LV handshake message
  const joinMsg = JSON.stringify(
    encodeMsg(1, 0, topic, "phx_join", {
      url: url,
      params: {
        _csrf_token: wsCsrfToken,
        _mounts: 0,
      },
      session: phxSession,
      static: phxStatic,
    })
  );
  
	const fetchFromApiMsg = JSON.stringify(
    encodeMsg(1, 4, topic, "event", {
			type: "click",
			event: "fetch_from_api",
			value: {value: ""}
    })
  );

	// Сделать проверку, сколько конектов улетело и сколько пришло ответов от LLM
  var response = ws.connect(
    ws_url,
    {
      headers: {
        Cookie: `_life_complex_key=${cookie}`,
        Origin: testHost,
      },
    },
		function (socket) {
			socket.on("open", () => {
				socket.send(joinMsg);
				sleep(1);
				socket.send(fetchFromApiMsg);
				if (debug) console.log(`websocket open: phx_join topic: ${topic}`);
			}),
			socket.on("message", (message) => {
				const messageId = JSON.parse(message).slice(0, 2);

				console.log("MESSAGE ID", messageId);
				switch (JSON.stringify(messageId)) {
					case `["1","4"]`:
						console.log(`Получение данных о начале загрузки`);
						checkMessage(message, `"status":"ok"`);
						checkMessage(message, "disabled phx-click=\\\"fetch_from_api\\\"");
						checkMessage(message, "Загрузка данных...");
						break;
					case `["1",null]`:
						console.log(`Ответ от llm ${message}`)
						check(message, {
							"llm click event OK":(message) => {
								return message.includes("phx-click=\\\"fetch_from_api\\\"") &&
								message.includes("Получить данные из API") &&
								message.includes("Привет! Брат!");
							}
						})
						// checkMessage(message, "phx-click=\\\"fetch_from_api\\\"");
						// checkMessage(message, "Получить данные из API");
						// checkMessage(message, "Привет! Брат!");
						socket.close();
						break;
					case `["1","0"]`:
						console.log(`Join liveview ${topic}`)
						checkMessage(message, `"status":"ok"`);
						checkMessage(message, "phx_reply");
						break;
					default:
						console.log("Unexpected message", message);
				}
				// socket.close();
			});
			socket.on("error", handleWsError);
			socket.on("close", () => {
				// should we issue a phx_leave here?
				if (debug) console.log("websocket disconnected");
			});
			socket.setTimeout(() => {
				console.log("2 seconds passed, closing the socket");
				socket.close();
				fail("websocket closed");
			}, 50000);
		}
  );

  checkStatus(response, 101);
  
	sleep(1);
}

function encodeMsg(id, seq, topic, event, msg) {
  return [`${id}`, `${seq}`, topic, event, msg];
}

function handleWsError(e) {
  if (e.error() != "websocket: close sent") {
    let msg = `An unexpected error occurred: ${e.error()}`;
    if (debug) console.log(msg);
    fail(msg);
  }
}

function grabLVProps(response) {
  let elem = response.html().find("meta[name='csrf-token']");
  let wsCsrfToken = elem.attr("content");

  if (!check(wsCsrfToken, { "found WS token ": (token) => !!token })) {
    fail("websocket csrf token not found");
  }

  elem = response.html().find("div[data-phx-main]");
  let phxSession = elem.data("phx-session");
  let phxStatic = elem.data("phx-static");
  let phxId = elem.attr("id");

  if (!check(phxSession, { "found phx-session": (str) => !!str })) {
    fail("session token not found");
  }

  if (!check(phxStatic, { "found phx-static": (str) => !!str })) {
    fail("static token not found");
  }

  return { wsCsrfToken, phxSession, phxStatic, phxId };
}

export function checkStatus(response, status, msg = "request failed") {
  if (
    !check(response, {
      "status OK": (res) => res.status.toString() === `${status}`,
    })
  ) {
    fail(`${msg} (Status: ${response.status.toString()}. Expected: ${status})`);
  }
}

export function checkMessage(message, regex, msg = "unexpected ws message") {
  if (!check(msg, { "ws msg OK": () => message.includes(regex) })) {
    console.log(message);
    fail(`${msg} (Msg: ${message}. Expected: ${regex})`);
  }
}
